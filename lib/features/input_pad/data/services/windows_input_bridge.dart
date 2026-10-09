import 'dart:async';

import 'package:cross_platform_whiteboard/features/session/data/services/realtime_session_service.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Forwards authenticated LAN input events to the native Windows input API.
class WindowsInputBridge {
  WindowsInputBridge(this._session) {
    if (!_isWindows) return;
    _subscription = _session.incomingMessages.listen(_handleMessage);
  }

  static const MethodChannel _channel =
      MethodChannel('cross_platform_whiteboard/system_input');

  final RealtimeSessionService _session;
  StreamSubscription<SessionMessage>? _subscription;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> _handleMessage(SessionMessage message) async {
    final bool forcedRelease =
        message.type == SessionEventType.pointerUp &&
        message.senderId == 'session-host';
    if ((!_session.isHost && !forcedRelease) ||
        message.senderId == _session.clientId) {
      return;
    }

    final Map<String, dynamic> payload = message.payload;
    try {
      switch (message.type) {
        case SessionEventType.pointerMoveAbsolute:
          await _channel.invokeMethod<void>(
            'moveAbsolute',
            <String, dynamic>{
              'x': _number(payload['x']),
              'y': _number(payload['y']),
            },
          );
          break;
        case SessionEventType.pointerMove:
          await _channel.invokeMethod<void>('moveRelative', <String, dynamic>{
            'dx': _number(payload['dx']),
            'dy': _number(payload['dy']),
          });
          break;
        case SessionEventType.pointerDown:
          await _channel.invokeMethod<void>('buttonDown');
          break;
        case SessionEventType.pointerUp:
          await _channel.invokeMethod<void>('buttonUp');
          break;
        case SessionEventType.scroll:
          await _channel.invokeMethod<void>('scroll', <String, dynamic>{
            'dx': _number(payload['dx']),
            'dy': _number(payload['dy']),
          });
          break;
        case SessionEventType.zoom:
          await _channel.invokeMethod<void>('zoom', <String, dynamic>{
            'delta': _number(payload['delta']),
          });
          break;
      }
    } on MissingPluginException {
      // The native system-input bridge exists only in the Windows runner.
    } on PlatformException {
      // Native input failures must not crash the session listener.
    }
  }

  double _number(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : 0;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
