import 'package:flutter/foundation.dart';

@immutable
class DrawingPoint {
  const DrawingPoint({
    required this.x,
    required this.y,
    this.pressure = 1,
    this.timestampMicros = 0,
  });

  /// Coordinates normalized to the logical canvas size (0..1).
  final double x;
  final double y;
  final double pressure;
  final int timestampMicros;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'x': x,
        'y': y,
        'pressure': pressure,
        'timestampMicros': timestampMicros,
      };

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    final Object? rawX = json['x'];
    final Object? rawY = json['y'];
    final Object? rawPressure = json['pressure'] ?? 1;
    final Object? rawTimestamp = json['timestampMicros'] ?? 0;
    if (rawX is! num || rawY is! num || rawPressure is! num || rawTimestamp is! num) {
      throw const FormatException('Invalid drawing point values.');
    }

    final double x = rawX.toDouble();
    final double y = rawY.toDouble();
    final double pressure = rawPressure.toDouble();
    if (!x.isFinite || !y.isFinite || !pressure.isFinite ||
        x < 0 || x > 1 || y < 0 || y > 1 || pressure < 0 || pressure > 1) {
      throw const FormatException('Drawing point values are out of range.');
    }

    return DrawingPoint(
      x: x,
      y: y,
      pressure: pressure,
      timestampMicros: rawTimestamp.toInt(),
    );
  }

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
