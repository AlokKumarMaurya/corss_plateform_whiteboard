import 'dart:async';

import 'package:cross_platform_whiteboard/features/drawing/data/repositories/in_memory_drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_tool.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_message.dart';
import 'package:cross_platform_whiteboard/features/session/domain/repositories/drawing_sync_gateway.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/controllers/whiteboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDrawingRepository repository;
  late _FakeDrawingSyncGateway sync;
  late WhiteboardController controller;

  setUp(() {
    repository = InMemoryDrawingRepository();
    sync = _FakeDrawingSyncGateway();
    controller = WhiteboardController(repository, sync)..onInit();
  });

  tearDown(() {
    controller.onClose();
    sync.dispose();
  });

  test('commits normalized strokes and publishes drawing events', () {
    controller.startStroke(const Offset(25, 50), const Size(100, 100));
    controller.appendPoint(const Offset(75, 80), const Size(100, 100));
    controller.finishStroke();

    expect(controller.strokes, hasLength(1));
    expect(controller.strokes.single.points.first.x, 0.25);
    expect(controller.strokes.single.points.first.y, 0.5);
    expect(repository.strokes, hasLength(1));
    expect(sync.published.map((SessionMessage message) => message.type), <String>[
      'stroke_started',
      'stroke_point',
      'stroke_ended',
    ]);
  });

  test('switching to eraser creates an eraser stroke', () {
    controller.setTool(DrawingTool.eraser);
    controller.startStroke(const Offset(10, 10), const Size(100, 100));
    controller.finishStroke();

    expect(controller.strokes.single.isEraser, isTrue);
  });

  test('undo and redo restore the last stroke', () {
    controller.startStroke(const Offset(10, 10), const Size(100, 100));
    controller.finishStroke();
    controller.undo();
    expect(controller.strokes, isEmpty);
    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isTrue);

    controller.redo();
    expect(controller.strokes, hasLength(1));
    expect(controller.canRedo, isFalse);
  });

  test('applies a remote stroke to the shared drawing repository', () async {
    const String remoteId = 'remote-stroke-1';
    sync.emit(const SessionMessage(
      senderId: 'browser-client',
      type: 'stroke_started',
      payload: <String, dynamic>{
        'stroke': <String, dynamic>{
          'id': remoteId,
          'points': <Map<String, dynamic>>[
            <String, dynamic>{
              'x': 0.25,
              'y': 0.5,
              'pressure': 1,
              'timestampMicros': 1,
            },
          ],
          'colorValue': 4278190080,
          'width': 3.5,
          'isEraser': false,
        },
      },
    ));
    sync.emit(const SessionMessage(
      senderId: 'browser-client',
      type: 'stroke_point',
      payload: <String, dynamic>{
        'strokeId': remoteId,
        'point': <String, dynamic>{
          'x': 0.75,
          'y': 0.8,
          'pressure': 1,
          'timestampMicros': 2,
        },
      },
    ));
    sync.emit(const SessionMessage(
      senderId: 'browser-client',
      type: 'stroke_ended',
      payload: <String, dynamic>{'strokeId': remoteId},
    ));
    await Future<void>.delayed(Duration.zero);

    expect(controller.strokes, hasLength(1));
    expect(controller.strokes.single.points, hasLength(2));
    expect(repository.strokes.single.points.last.x, 0.75);
  });
}

class _FakeDrawingSyncGateway implements DrawingSyncGateway {
  final StreamController<SessionMessage> _incoming =
      StreamController<SessionMessage>.broadcast(sync: true);
  final List<SessionMessage> published = <SessionMessage>[];

  @override
  String get clientId => 'test-client';

  @override
  bool get isHost => false;

  @override
  Stream<SessionMessage> get incomingMessages => _incoming.stream;

  @override
  void publish(SessionMessage message) => published.add(message);

  void emit(SessionMessage message) => _incoming.add(message);

  Future<void> dispose() => _incoming.close();
}
