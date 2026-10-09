import 'package:cross_platform_whiteboard/app/routes/app_routes.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/bindings/whiteboard_binding.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/screens/whiteboard_screen.dart';
import 'package:get/get.dart';

abstract final class AppPages {
  static const String initial = AppRoutes.home;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const WhiteboardScreen(),
      binding: WhiteboardBinding(),
    ),
  ];
}
