import 'package:cross_platform_whiteboard/app/routes/app_routes.dart';
import 'package:cross_platform_whiteboard/features/input_pad/presentation/screens/input_pad_screen.dart';
import 'package:cross_platform_whiteboard/features/session/presentation/screens/windows_companion_screen.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/bindings/whiteboard_binding.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/screens/whiteboard_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

abstract final class AppPages {
  static const String initial = AppRoutes.home;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return const InputPadScreen();
        }
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
          return const WindowsCompanionScreen();
        }
        return const WhiteboardScreen();
      },
      binding: WhiteboardBinding(),
    ),
  ];
}
