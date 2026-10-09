import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionMessage', () {
    test('round trips through JSON', () {
      const SessionMessage message = SessionMessage(
        senderId: 'test-client',
        type: SessionEventType.clearBoard,
        payload: <String, dynamic>{'reason': 'user_action'},
      );

      final SessionMessage decoded = SessionMessage.decode(message.encode());

      expect(decoded.version, SessionMessage.currentVersion);
      expect(decoded.senderId, message.senderId);
      expect(decoded.type, message.type);
      expect(decoded.payload, message.payload);
    });

    test('accepts remote pointer and gesture events', () {
      const List<String> inputEvents = <String>[
        SessionEventType.pointerMove,
        SessionEventType.pointerDown,
        SessionEventType.pointerUp,
        SessionEventType.scroll,
        SessionEventType.zoom,
      ];

      for (final String event in inputEvents) {
        final SessionMessage message = SessionMessage(
          senderId: 'phone',
          type: event,
          payload: const <String, dynamic>{'dx': 2.0, 'dy': -1.0},
        );

        expect(SessionMessage.decode(message.encode()).type, event);
      }
    });

    test('rejects an unsupported protocol version', () {
      expect(
        () => SessionMessage.fromJson(<String, dynamic>{
          'version': 99,
          'senderId': 'test-client',
          'type': SessionEventType.clearBoard,
          'payload': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown event types', () {
      expect(
        () => SessionMessage.fromJson(<String, dynamic>{
          'version': SessionMessage.currentVersion,
          'senderId': 'test-client',
          'type': 'execute_command',
          'payload': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });
  });
}
