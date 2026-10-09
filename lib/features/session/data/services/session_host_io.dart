import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:cross_platform_whiteboard/features/session/domain/repositories/session_host.dart';

SessionHost createSessionHost() => _IoSessionHost();

class _IoSessionHost implements SessionHost {
  final StreamController<SessionMessage> _messages =
      StreamController<SessionMessage>.broadcast();
  final Set<WebSocket> _clients = <WebSocket>{};

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _serverSubscription;
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
    if (_server != null) {
      throw StateError('A whiteboard session is already hosting.');
    }
    if (port < 1024 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Port must be between 1024 and 65535.');
    }

    _token = token;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _serverSubscription = _server!.listen(_handleRequest);
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    _localAddresses = interfaces
        .expand((NetworkInterface interface) => interface.addresses)
        .where((InternetAddress address) => address.type == InternetAddressType.IPv4)
        .map((InternetAddress address) => address.address)
        .toSet()
        .toList(growable: false);
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
    if (_clients.length >= 8) {
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
      if (source.length > 65536) {
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
    if (encoded.length > 65536) {
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
    await _serverSubscription?.cancel();
    _serverSubscription = null;
    for (final WebSocket socket in _clients.toList(growable: false)) {
      await socket.close(WebSocketStatus.normalClosure, 'Host closed session');
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _token = null;
    _localAddresses = <String>[];
  }
}
