import 'package:cross_platform_whiteboard/features/drawing/data/repositories/in_memory_drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/repositories/drawing_repository.dart';
import 'package:cross_platform_whiteboard/features/input_pad/data/services/windows_input_bridge.dart';
import 'package:cross_platform_whiteboard/features/input_pad/presentation/controllers/input_pad_controller.dart';
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
    Get.lazyPut<InputPadController>(
      () => InputPadController(Get.find<RealtimeSessionService>()),
    );
    // Eagerly attach the bridge on Windows so incoming phone events are
    // applied even when the Windows companion window is not in the foreground.
    Get.put<WindowsInputBridge>(
      WindowsInputBridge(Get.find<RealtimeSessionService>()),
    );
    Get.lazyPut<WhiteboardController>(
      () => WhiteboardController(
        Get.find<DrawingRepository>(),
        Get.find<DrawingSyncGateway>(),
      ),
    );
  }
}
