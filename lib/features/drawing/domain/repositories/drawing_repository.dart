import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_stroke.dart';

abstract interface class DrawingRepository {
  List<DrawingStroke> get strokes;
  void replaceStrokes(List<DrawingStroke> strokes);
}
