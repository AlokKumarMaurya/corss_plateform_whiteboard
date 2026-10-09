import 'package:cross_platform_whiteboard/features/drawing/data/repositories/in_memory_drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/repositories/drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/session/data/services/realtime_session_service.dart';
import 'package:cross_platform_whiteboard/features/session/domain/repositories/drawing_sync_gateway.dart';
import 'package:cross_platform_whiteboard/features/session/presentation/controllers/session_controller.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/controllers/whiteboard_controller.dart';
import 'package:get/get.dart';

class WhiteboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DrawingRepository>(InMemoryDrawingRepository.new);
    Get.lazyPut<RealtimeSessionService>(RealtimeSessionService.new);
    Get.lazyPut<DrawingSyncGateway>(
      () => Get.find<RealtimeSessionService>(),
    );
    Get.lazyPut<SessionController>(
      () => SessionController(Get.find<RealtimeSessionService>()),
    );
    Get.lazyPut<WhiteboardController>(
      () => WhiteboardController(
        Get.find<DrawingRepository>(),
        Get.find<DrawingSyncGateway>(),
      ),
    );
  }
}
