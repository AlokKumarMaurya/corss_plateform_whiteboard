import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/input_pad/presentation/controllers/input_pad_controller.dart';
import 'package:cross_platform_whiteboard/features/session/presentation/widgets/session_panel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InputPadScreen extends GetView<InputPadController> {
  const InputPadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SessionPanel(),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF171B24),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF303746)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: controller.pointerDown,
                    onPointerMove: controller.pointerMove,
                    onPointerUp: controller.pointerUp,
                    onPointerCancel: controller.pointerCancel,
                    child: Obx(
                      () => Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PadGridPainter(
                                navigating: controller.isNavigating,
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  controller.isNavigating
                                      ? Icons.open_with_rounded
                                      : Icons.gesture_rounded,
                                  color: const Color(0xFFCAD5EA),
                                  size: 42,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  controller.hint,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFE7ECF5),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'One contact writes  •  Two contacts navigate',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF929DB1),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Keep this app open while the Windows companion is connected. '
                'The phone sends input to whichever application is active on Windows.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF737D8F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PadGridPainter extends CustomPainter {
  const _PadGridPainter({required this.navigating});

  final bool navigating;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = navigating
          ? const Color(0xFF4C78D0).withValues(alpha: 0.22)
          : const Color(0xFF647086).withValues(alpha: 0.16)
      ..strokeWidth = 1;
    const double spacing = 28;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PadGridPainter oldDelegate) =>
      oldDelegate.navigating != navigating;
}
