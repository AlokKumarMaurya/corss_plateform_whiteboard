import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_point.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_stroke.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/controllers/whiteboard_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({required this.controller, super.key});
  final WhiteboardController controller;

  @override
  Widget build(BuildContext context) => Semantics(
        label: AppStrings.canvasSemanticsLabel,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size size = Size(constraints.maxWidth, constraints.maxHeight);
            return Listener(
              onPointerDown: (PointerDownEvent event) {
                if (event.kind == PointerDeviceKind.mouse &&
                    event.buttons != kPrimaryButton) {
                  return;
                }
                controller.startStroke(
                  event.localPosition,
                  size,
                  pressure: _normalizedPressure(event),
                );
              },
              onPointerMove: (PointerMoveEvent event) {
                if (controller.activeStroke.value == null) {
                  return;
                }
                controller.appendPoint(
                  event.localPosition,
                  size,
                  pressure: _normalizedPressure(event),
                );
              },
              onPointerUp: (_) => controller.finishStroke(),
              onPointerCancel: (_) => controller.finishStroke(),
              child: ColoredBox(
                color: Colors.white,
                child: RepaintBoundary(
                  child: Obx(
                    () => CustomPaint(
                      painter: _DrawingPainter(
                        strokes: controller.strokes,
                        activeStroke: controller.activeStroke.value,
                      ),
                      size: size,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  double _normalizedPressure(PointerEvent event) {
    if (event.kind != PointerDeviceKind.stylus &&
        event.kind != PointerDeviceKind.invertedStylus) {
      return 1;
    }
    final double range = event.pressureMax - event.pressureMin;
    if (range <= 0) {
      return 1;
    }
    return ((event.pressure - event.pressureMin) / range)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class _DrawingPainter extends CustomPainter {
  const _DrawingPainter({required this.strokes, required this.activeStroke});

  final List<DrawingStroke> strokes;
  final DrawingStroke? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final DrawingStroke stroke in <DrawingStroke>[
      ...strokes,
      if (activeStroke != null) activeStroke!,
    ]) {
      _paintStroke(canvas, size, stroke);
    }
  }

  void _paintStroke(Canvas canvas, Size size, DrawingStroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }
    final Paint paint = Paint()
      ..color = Color(stroke.colorValue)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;
    final Offset first = _toCanvasPoint(stroke.points.first, size);
    if (stroke.points.length == 1) {
      canvas.drawCircle(first, stroke.width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final Path path = Path()..moveTo(first.dx, first.dy);
    for (int index = 1; index < stroke.points.length; index++) {
      final Offset point = _toCanvasPoint(stroke.points[index], size);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  Offset _toCanvasPoint(DrawingPoint point, Size size) =>
      Offset(point.x * size.width, point.y * size.height);

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.activeStroke != activeStroke;
}
