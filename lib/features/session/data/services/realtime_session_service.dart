import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cross_platform_whiteboard/features/session/data/services/session_host_factory.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_status.dart';
import 'package:cross_platform_whiteboard/features/session/domain/repositories/drawing_sync_gateway.dart';
import 'package:cross_platform_whiteboard/features/session/domain/repositories/session_host.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeSessionService extends GetxService implements DrawingSyncGateway {
  RealtimeSessionService() : _clientId = _randomHex(16);

  static const int defaultPort = 8765;
  static const int _maximumMessageLength = 65536;

  final SessionHost _host = createSessionHost();
  final String _clientId;
  final StreamController<SessionMessage> _incoming =
      StreamController<SessionMessage>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<SessionMessage>? _hostSubscription;
  StreamSubscription<dynamic>? _clientSubscription;

  final Rx<SessionStatus> status = SessionStatus.disconnected.obs;
  final RxList<String> hostAddresses = <String>[].obs;
  final RxString sessionToken = ''.obs;
  final RxString errorMessage = ''.obs;

  @override
  String get clientId => _clientId;

  @override
  bool get isHost => status.value == SessionStatus.hosting;

  @override
  Stream<SessionMessage> get incomingMessages => _incoming.stream;

  Future<void> startHost({int port = defaultPort}) async {
    await disconnect();
    status.value = SessionStatus.connecting;
    errorMessage.value = '';
    final String token = _randomHex(32);

    try {
      await _host.start(token: token, port: port);
      _hostSubscription = _host.messages.listen(_incoming.add);
      hostAddresses.assignAll(_host.localAddresses);
      sessionToken.value = token;
      status.value = SessionStatus.hosting;
    } catch (error) {
      errorMessage.value = _friendlyError(error);
      status.value = SessionStatus.disconnected;
      await _host.close();
    }
  }

  Future<void> connect({
    required String host,
    required String token,
    int port = defaultPort,
  }) async {
    await disconnect();
    status.value = SessionStatus.connecting;
    errorMessage.value = '';

    try {
      final Uri uri = Uri(
        scheme: 'ws',
        host: host.trim(),
        port: port,
        path: '/whiteboard',
        queryParameters: <String, String>{'token': token.trim()},
      );
      final WebSocketChannel channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 8));
      _clientSubscription = channel.stream.listen(
        _handleClientMessage,
        onError: (Object error, StackTrace stackTrace) {
          errorMessage.value = _friendlyError(error);
          status.value = SessionStatus.disconnected;
        },
        onDone: () {
          if (status.value == SessionStatus.connected) {
            status.value = SessionStatus.disconnected;
          }
        },
        cancelOnError: true,
      );
      status.value = SessionStatus.connected;
      publish(
        SessionMessage(
          senderId: clientId,
          type: SessionEventType.requestSnapshot,
          payload: const <String, dynamic>{},
        ),
      );
    } catch (error) {
      errorMessage.value = _friendlyError(error);
      status.value = SessionStatus.disconnected;
      await _clientSubscription?.cancel();
      _clientSubscription = null;
      await _channel?.sink.close();
      _channel = null;
    }
  }

  @override
  void publish(SessionMessage message) {
    if (status.value == SessionStatus.hosting) {
      _host.broadcast(message);
      _incoming.add(message);
      return;
    }
    if (status.value == SessionStatus.connected && _channel != null) {
      _channel!.sink.add(message.encode());
    }
  }

  void _handleClientMessage(dynamic raw) {
    try {
      final String source = raw is String ? raw : utf8.decode(raw as List<int>);
      if (source.length > _maximumMessageLength) {
        errorMessage.value = 'A session message exceeded the size limit.';
        unawaited(disconnect());
        return;
      }
      _incoming.add(SessionMessage.decode(source));
    } on Object catch (error) {
      errorMessage.value = _friendlyError(error);
      unawaited(disconnect());
    }
  }

  Future<void> disconnect() async {
    await _clientSubscription?.cancel();
    _clientSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    await _hostSubscription?.cancel();
    _hostSubscription = null;
    await _host.close();
    hostAddresses.clear();
    sessionToken.value = '';
    status.value = SessionStatus.disconnected;
  }

  String _friendlyError(Object error) {
    if (error is UnsupportedError) {
      return error.message?.toString() ??
          'Session hosting is not supported on this platform.';
    }
    final String message = error.toString();
    if (message.contains('Connection refused') || message.contains('Failed host lookup')) {
      return 'Could not reach the host. Check the IP address, Wi-Fi, and Windows Firewall.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  static String _randomHex(int byteCount) {
    final Random random = Random.secure();
    return List<String>.generate(
      byteCount * 2,
      (_) => random.nextInt(16).toRadixString(16),
      growable: false,
    ).join();
  }

  @override
  void onClose() {
    unawaited(disconnect());
    unawaited(_incoming.close());
    super.onClose();
  }
}
