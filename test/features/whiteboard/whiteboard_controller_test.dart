import 'package:cross_platform_whiteboard/features/drawing/data/repositories/in_memory_drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_tool.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/controllers/whiteboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDrawingRepository repository;
  late WhiteboardController controller;

  setUp(() {
    repository = InMemoryDrawingRepository();
    controller = WhiteboardController(repository);
  });

  tearDown(() => controller.onClose());

  test('commits a normalized stroke when drawing finishes', () {
    controller.startStroke(const Offset(25, 50), const Size(100, 100));
    controller.appendPoint(const Offset(75, 80), const Size(100, 100));
    controller.finishStroke();
    expect(controller.strokes, hasLength(1));
    expect(controller.strokes.single.points.first.x, 0.25);
    expect(controller.strokes.single.points.first.y, 0.5);
    expect(repository.strokes, hasLength(1));
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
}
