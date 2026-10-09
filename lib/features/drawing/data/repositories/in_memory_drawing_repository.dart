import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_stroke.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/repositories/drawing_repository.dart';

class InMemoryDrawingRepository implements DrawingRepository {
  List<DrawingStroke> _strokes = <DrawingStroke>[];

  @override
  List<DrawingStroke> get strokes => List<DrawingStroke>.unmodifiable(_strokes);

  @override
  void replaceStrokes(List<DrawingStroke> strokes) {
    _strokes = List<DrawingStroke>.of(strokes);
  }
}
