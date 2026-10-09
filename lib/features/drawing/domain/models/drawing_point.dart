import 'package:flutter/foundation.dart';

@immutable
class DrawingPoint {
  const DrawingPoint({
    required this.x,
    required this.y,
    this.pressure = 1,
    this.timestampMicros = 0,
  });

  /// Position normalized to the logical canvas size, in the range 0..1.
  final double x;
  final double y;
  final double pressure;
  final int timestampMicros;

  DrawingPoint copyWith({
    double? x,
    double? y,
    double? pressure,
    int? timestampMicros,
  }) {
    return DrawingPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
      timestampMicros: timestampMicros ?? this.timestampMicros,
    );
  }
}
