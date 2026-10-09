import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_platform_whiteboard/core/constants/session_constants.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:cross_platform_whiteboard/features/session/domain/repositories/session_host.dart';

SessionHost createSessionHost() => _IoSessionHost();

class _IoSessionHost implements SessionHost {
  final StreamController<SessionMessage> _messages =
      StreamController<SessionMessage>.broadcast();
  final Set<WebSocket> _clients = <WebSocket>{};
  final List<HttpServer> _servers = <HttpServer>[];
  final List<StreamSubscription<HttpRequest>> _serverSubscriptions =
      <StreamSubscription<HttpRequest>>[];

  String? _token;
  List<String> _localAddresses = <String>[];

  @override
  Stream<SessionMessage> get messages => _messages.stream;

  @override
  List<String> get localAddresses => List<String>.unmodifiable(_localAddresses);

  @override
  Future<void> start({required String token, required int port}) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Only the Windows desktop app can host a session.');
    }
    if (_servers.isNotEmpty) {
      throw StateError('A whiteboard session is already hosting.');
    }
    if (port < 1024 || port > 65535) {
      throw ArgumentError.value(
        port,
        'port',
        'Port must be between 1024 and 65535.',
      );
    }

    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final List<String> privateAddresses = interfaces
        .expand((NetworkInterface interface) => interface.addresses)
        .where(
          (InternetAddress address) =>
              address.type == InternetAddressType.IPv4 &&
              _isPrivateIpv4(address.address),
        )
        .map((InternetAddress address) => address.address)
        .toSet()
        .toList(growable: false);

    if (privateAddresses.isEmpty) {
      throw StateError(
        'No private IPv4 address found. Connect to a private Wi-Fi or LAN network.',
      );
    }

    _token = token;
    for (final String address in privateAddresses) {
      final HttpServer server = await HttpServer.bind(
        InternetAddress(address),
        port,
      );
      _servers.add(server);
      _serverSubscriptions.add(server.listen(_handleRequest));
    }
    _localAddresses = privateAddresses;
  }

  bool _isPrivateIpv4(String address) {
    final List<int> octets = address.split('.').map(int.parse).toList();
    if (octets.length != 4) {
      return false;
    }
    return octets[0] == 10 ||
        (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
        (octets[0] == 192 && octets[1] == 168);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path != '/whiteboard') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    if (request.uri.queryParameters['token'] != _token) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }
    if (_clients.length >= SessionConstants.maximumClients) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      return;
    }

    try {
      final WebSocket socket = await WebSocketTransformer.upgrade(request);
      _clients.add(socket);
      socket.listen(
        (Object? raw) => _handleMessage(socket, raw),
        onError: (Object error, StackTrace stackTrace) => _clients.remove(socket),
        onDone: () => _clients.remove(socket),
        cancelOnError: true,
      );
    } on WebSocketException {
      // The upgrade can fail after the response has started; do not attempt
      // to write a second HTTP response in that case.
    }
  }

  void _handleMessage(WebSocket socket, Object? raw) {
    try {
      final String source;
      if (raw is String) {
        source = raw;
      } else if (raw is List<int>) {
        source = utf8.decode(raw);
      } else {
        throw const FormatException('Unsupported WebSocket frame.');
      }
      if (source.length > SessionConstants.maximumMessageBytes) {
        socket.close(WebSocketStatus.messageTooBig, 'Message too large');
        _clients.remove(socket);
        return;
      }
      final SessionMessage message = SessionMessage.decode(source);
      _messages.add(message);
      broadcast(message);
    } on FormatException {
      socket.close(WebSocketStatus.protocolError, 'Invalid session message');
      _clients.remove(socket);
    }
  }

  @override
  void broadcast(SessionMessage message) {
    final String encoded = message.encode();
    if (encoded.length > SessionConstants.maximumMessageBytes) {
      return;
    }
    for (final WebSocket socket in _clients.toList(growable: false)) {
      if (socket.readyState == WebSocket.open) {
        socket.add(encoded);
      }
    }
  }

  @override
  Future<void> close() async {
    for (final StreamSubscription<HttpRequest> subscription
        in _serverSubscriptions) {
      await subscription.cancel();
    }
    _serverSubscriptions.clear();
    for (final WebSocket socket in _clients.toList(growable: false)) {
      await socket.close(
        WebSocketStatus.normalClosure,
        'Host closed session',
      );
    }
    _clients.clear();
    for (final HttpServer server in _servers) {
      await server.close(force: true);
    }
    _servers.clear();
    _token = null;
    _localAddresses = <String>[];
  }
}
