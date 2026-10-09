import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrawingPoint', () {
    test('stores normalized position and pressure', () {
      const DrawingPoint point = DrawingPoint(x: 0.5, y: 0.25, pressure: 0.8, timestampMicros: 42);
      expect(point.x, 0.5);
      expect(point.y, 0.25);
      expect(point.pressure, 0.8);
      expect(point.timestampMicros, 42);
    });

    test('copyWith only replaces provided values', () {
      const DrawingPoint point = DrawingPoint(x: 0.2, y: 0.7);
      final DrawingPoint copied = point.copyWith(x: 0.4);
      expect(copied.x, 0.4);
      expect(copied.y, 0.7);
      expect(copied.pressure, 1);
    });
  });
}
