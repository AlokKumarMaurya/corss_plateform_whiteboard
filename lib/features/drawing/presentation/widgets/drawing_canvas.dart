import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_point.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_stroke.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/controllers/whiteboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({
    required this.controller,
    super.key,
  });

  final WhiteboardController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Whiteboard drawing area',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size canvasSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return Listener(
            onPointerDown: (PointerDownEvent event) {
              if (event.kind == PointerDeviceKind.mouse &&
                  event.buttons != kPrimaryButton) {
                return;
              }
              controller.startStroke(
                event.localPosition,
                canvasSize,
                pressure: event.pressure,
              );
            },
            onPointerMove: (PointerMoveEvent event) {
              if (controller.activeStroke.value == null) {
                return;
              }
              controller.appendPoint(
                event.localPosition,
                canvasSize,
                pressure: event.pressure,
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
                    size: canvasSize,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  const _DrawingPainter({
    required this.strokes,
    required this.activeStroke,
  });

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
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final Offset firstPoint = _toCanvasPoint(stroke.points.first, size);
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        firstPoint,
        stroke.width / 2,
        Paint()
          ..color = stroke.color
          ..isAntiAlias = true
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final Path path = Path()..moveTo(firstPoint.dx, firstPoint.dy);
    for (int index = 1; index < stroke.points.length; index++) {
      final Offset point = _toCanvasPoint(stroke.points[index], size);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  Offset _toCanvasPoint(DrawingPoint point, Size size) {
    return Offset(point.x * size.width, point.y * size.height);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activeStroke != activeStroke;
  }
}
