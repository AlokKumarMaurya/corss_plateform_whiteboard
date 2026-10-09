import 'dart:math' as math;

import 'package:cross_platform_whiteboard/core/constants/drawing_constants.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_point.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_stroke.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_tool.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/repositories/drawing_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhiteboardController extends GetxController {
  WhiteboardController(this._repository);

  final DrawingRepository _repository;
  final RxList<DrawingStroke> _strokes = <DrawingStroke>[].obs;
  final Rxn<DrawingStroke> activeStroke = Rxn<DrawingStroke>();
  final Rx<DrawingTool> selectedTool = DrawingTool.pen.obs;
  final Rx<Color> selectedColor = DrawingConstants.defaultColor.obs;
  final RxDouble strokeWidth = DrawingConstants.defaultStrokeWidth.obs;
  final RxBool _canRedo = false.obs;
  final List<DrawingStroke> _redoStack = <DrawingStroke>[];

  List<DrawingStroke> get strokes => _strokes.toList(growable: false);
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _canRedo.value;
  bool get isEmpty => _strokes.isEmpty && activeStroke.value == null;

  @override
  void onInit() {
    super.onInit();
    _strokes.assignAll(_repository.strokes);
  }

  void setTool(DrawingTool tool) => selectedTool.value = tool;

  void setColor(Color color) {
    selectedColor.value = color;
    selectedTool.value = DrawingTool.pen;
  }

  void setStrokeWidth(double width) {
    strokeWidth.value = width
        .clamp(DrawingConstants.minimumStrokeWidth, DrawingConstants.maximumStrokeWidth)
        .toDouble();
  }

  void startStroke(Offset position, Size size, {double pressure = 1}) {
    if (size.isEmpty) return;
    final bool erasing = selectedTool.value == DrawingTool.eraser;
    activeStroke.value = DrawingStroke(
      id: _createStrokeId(),
      points: <DrawingPoint>[_normalizePoint(position, size, pressure)],
      color: erasing ? Colors.white : selectedColor.value,
      width: erasing ? math.max(strokeWidth.value * 4, 16) : strokeWidth.value,
      isEraser: erasing,
    );
  }

  void appendPoint(Offset position, Size size, {double pressure = 1}) {
    final DrawingStroke? current = activeStroke.value;
    if (current == null || size.isEmpty) return;
    activeStroke.value = current.copyWith(
      points: <DrawingPoint>[
        ...current.points,
        _normalizePoint(position, size, pressure),
      ],
    );
  }

  void finishStroke() {
    final DrawingStroke? stroke = activeStroke.value;
    if (stroke == null) return;
    _strokes.add(stroke);
    _repository.replaceStrokes(_strokes);
    _redoStack.clear();
    _canRedo.value = false;
    activeStroke.value = null;
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _redoStack.add(_strokes.removeLast());
    _canRedo.value = true;
    _repository.replaceStrokes(_strokes);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _strokes.add(_redoStack.removeLast());
    _canRedo.value = _redoStack.isNotEmpty;
    _repository.replaceStrokes(_strokes);
  }

  void clearCanvas() {
    _strokes.clear();
    activeStroke.value = null;
    _redoStack.clear();
    _canRedo.value = false;
    _repository.replaceStrokes(_strokes);
  }

  DrawingPoint _normalizePoint(Offset position, Size size, double pressure) =>
      DrawingPoint(
        x: (position.dx / size.width).clamp(0.0, 1.0).toDouble(),
        y: (position.dy / size.height).clamp(0.0, 1.0).toDouble(),
        pressure: pressure.isFinite ? pressure.clamp(0.0, 1.0).toDouble() : 1,
        timestampMicros: DateTime.now().microsecondsSinceEpoch,
      );

  String _createStrokeId() => '${DateTime.now().microsecondsSinceEpoch}-${_strokes.length}';
}
