import 'dart:ui' show Size;

import 'package:cross_platform_whiteboard/features/input_pad/presentation/controllers/input_pad_controller.dart';
import 'package:cross_platform_whiteboard/features/session/data/services/realtime_session_service.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_event_type.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingSessionService session;
  late InputPadController controller;

  setUp(() {
    session = _RecordingSessionService();
    controller = InputPadController(session);
  });

  tearDown(() {
    controller.onClose();
  });

  test('move mode moves the pointer without holding the mouse button', () {
    controller.setWriteMode(false);
    controller.setPointerSensitivity(2);

    controller.pointerDown(
      const PointerDownEvent(
        pointer: 1,
        kind: PointerDeviceKind.touch,
        position: Offset.zero,
      ),
    );
    controller.pointerMove(
      const PointerMoveEvent(
        pointer: 1,
        kind: PointerDeviceKind.touch,
        position: Offset(10, 5),
      ),
    );
    controller.pointerUp(
      const PointerUpEvent(
        pointer: 1,
        kind: PointerDeviceKind.touch,
        position: Offset(10, 5),
      ),
    );

    expect(
      session.messages.map((SessionMessage message) => message.type),
      <String>[SessionEventType.pointerMove],
    );
    expect(session.messages.single.payload['dx'], 20.0);
    expect(session.messages.single.payload['dy'], 10.0);
  });

  test('write mode draws with a down, move, and up sequence', () {
    controller.pointerDown(
      const PointerDownEvent(
        pointer: 1,
        kind: PointerDeviceKind.touch,
        position: Offset.zero,
      ),
    );
    controller.pointerMove(
      const PointerMoveEvent(
        pointer: 1,
        kind: PointerDeviceKind.touch,
        position: Offset(8, 3),
      ),
    );
    controller.pointerUp(
      const PointerUpEvent(
        pointer: 1,
        kind: PointerDeviceKind.touch,
        position: Offset(8, 3),
      ),
    );

    expect(
      session.messages.map((SessionMessage message) => message.type),
      <String>[
        SessionEventType.pointerDown,
        SessionEventType.pointerMove,
        SessionEventType.pointerUp,
      ],
    );
  });

  test('tablet mode maps each touch position to absolute desktop coordinates', () {
    controller.setPadSize(const Size(100, 200));
    controller.setTabletMode(true);

    controller.pointerDown(
      const PointerDownEvent(
        pointer: 1,
        kind: PointerDeviceKind.stylus,
        position: Offset(25, 50),
      ),
    );
    controller.pointerMove(
      const PointerMoveEvent(
        pointer: 1,
        kind: PointerDeviceKind.stylus,
        position: Offset(35, 70),
      ),
    );
    controller.pointerUp(
      const PointerUpEvent(
        pointer: 1,
        kind: PointerDeviceKind.stylus,
        position: Offset(35, 70),
      ),
    );

    expect(
      session.messages.map((SessionMessage message) => message.type),
      <String>[
        SessionEventType.pointerMoveAbsolute,
        SessionEventType.pointerDown,
        SessionEventType.pointerMoveAbsolute,
        SessionEventType.pointerUp,
      ],
    );
    expect(session.messages[0].payload['x'], 0.25);
    expect(session.messages[0].payload['y'], 0.25);
    expect(session.messages[2].payload['x'], 0.35);
    expect(session.messages[2].payload['y'], 0.35);
  });

  test('stylus hover repositions the pointer without drawing', () {
    controller.pointerHover(
      const PointerHoverEvent(
        pointer: 1,
        kind: PointerDeviceKind.stylus,
        position: Offset(4, 6),
        delta: Offset(4, 6),
      ),
    );

    expect(
      session.messages.map((SessionMessage message) => message.type),
      <String>[SessionEventType.pointerMove],
    );
    expect(session.messages.single.payload['dx'], 4.0);
    expect(session.messages.single.payload['dy'], 6.0);
  });

  test('sensitivity settings stay within supported ranges', () {
    controller.setPointerSensitivity(9);
    controller.setScrollSensitivity(20);

    expect(controller.pointerSensitivity, 2.5);
    expect(controller.scrollSensitivity, 14.0);
  });
}

class _RecordingSessionService extends RealtimeSessionService {
  final List<SessionMessage> messages = <SessionMessage>[];

  @override
  bool get isHost => true;

  @override
  String get clientId => 'test-client';

  @override
  void publish(SessionMessage message) {
    messages.add(message);
  }
}
