import 'package:cross_platform_whiteboard/features/drawing/data/repositories/in_memory_drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/repositories/drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/controllers/whiteboard_controller.dart';
import 'package:get/get.dart';

class WhiteboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DrawingRepository>(InMemoryDrawingRepository.new);
    Get.lazyPut<WhiteboardController>(
      () => WhiteboardController(Get.find<DrawingRepository>()),
    );
  }
}
