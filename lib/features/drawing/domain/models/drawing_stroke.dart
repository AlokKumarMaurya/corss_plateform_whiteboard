import 'package:cross_platform_whiteboard/core/constants/drawing_constants.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_point.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class DrawingStroke {
  const DrawingStroke({
    required this.id,
    required this.points,
    this.color = DrawingConstants.defaultColor,
    this.width = DrawingConstants.defaultStrokeWidth,
    this.isEraser = false,
  });

  final String id;
  final List<DrawingPoint> points;
  final Color color;
  final double width;
  final bool isEraser;

  DrawingStroke copyWith({
    List<DrawingPoint>? points,
    Color? color,
    double? width,
    bool? isEraser,
  }) {
    return DrawingStroke(
      id: id,
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}
