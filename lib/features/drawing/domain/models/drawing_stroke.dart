import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_point.dart';
import 'package:flutter/foundation.dart';

@immutable
class DrawingStroke {
  const DrawingStroke({
    required this.id,
    required this.points,
    required this.colorValue,
    required this.width,
    this.isEraser = false,
  });

  final String id;
  final List<DrawingPoint> points;
  /// ARGB integer, kept independent of Flutter's Color API.
  final int colorValue;
  final double width;
  final bool isEraser;

  DrawingStroke copyWith({
    List<DrawingPoint>? points,
    int? colorValue,
    double? width,
    bool? isEraser,
  }) {
    return DrawingStroke(
      id: id,
      points: points ?? this.points,
      colorValue: colorValue ?? this.colorValue,
      width: width ?? this.width,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}
