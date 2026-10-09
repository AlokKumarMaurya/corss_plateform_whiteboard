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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'points': points.map((DrawingPoint point) => point.toJson()).toList(),
        'colorValue': colorValue,
        'width': width,
        'isEraser': isEraser,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? points = json['points'];
    final Object? colorValue = json['colorValue'];
    final Object? width = json['width'];
    final Object? isEraser = json['isEraser'] ?? false;

    if (id is! String || id.isEmpty || id.length > 128 ||
        points is! List<dynamic> || colorValue is! num ||
        width is! num || isEraser is! bool) {
      throw const FormatException('Invalid drawing stroke.');
    }

    final double strokeWidth = width.toDouble();
    if (!strokeWidth.isFinite || strokeWidth <= 0 || strokeWidth > 256) {
      throw const FormatException('Drawing stroke width is out of range.');
    }

    final List<DrawingPoint> parsedPoints = points.map((Object? point) {
      if (point is! Map<String, dynamic>) {
        throw const FormatException('Invalid point in drawing stroke.');
      }
      return DrawingPoint.fromJson(point);
    }).toList(growable: false);

    return DrawingStroke(
      id: id,
      points: parsedPoints,
      colorValue: colorValue.toInt(),
      width: strokeWidth,
      isEraser: isEraser,
    );
  }

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
