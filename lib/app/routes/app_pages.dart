import 'package:cross_platform_whiteboard/app/routes/app_routes.dart';
import 'package:cross_platform_whiteboard/features/input_pad/presentation/screens/input_pad_screen.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/bindings/whiteboard_binding.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/screens/whiteboard_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

abstract final class AppPages {
  static const String initial = AppRoutes.home;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? const InputPadScreen()
          : const WhiteboardScreen(),
      binding: WhiteboardBinding(),
    ),
  ];
}
