import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/input_pad/presentation/controllers/input_pad_controller.dart';
import 'package:cross_platform_whiteboard/features/session/presentation/widgets/session_panel.dart';
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
              const SizedBox(height: 8),
              _InputPadControls(controller: controller),
              const SizedBox(height: 8),
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
                                writeMode: controller.writeMode,
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    controller.isNavigating
                                        ? Icons.open_with_rounded
                                        : controller.writeMode
                                            ? Icons.gesture_rounded
                                            : Icons.ads_click_rounded,
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
                                    AppStrings.twoFingerHint,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF929DB1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep this app open while the Windows companion is connected.',
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

class _InputPadControls extends StatelessWidget {
  const _InputPadControls({required this.controller});

  final InputPadController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      AppStrings.inputMode,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.draw_rounded),
                        label: Text(AppStrings.modeWrite),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.mouse_rounded),
                        label: Text(AppStrings.modeMove),
                      ),
                    ],
                    selected: <bool>{controller.writeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<bool> selection) {
                      controller.setWriteMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
            ExpansionTile(
              dense: true,
              title: const Text(AppStrings.inputSettings),
              subtitle: Text(
                '${AppStrings.pointerSpeed}: '
                '${controller.pointerSensitivity.toStringAsFixed(1)}×  ·  '
                '${AppStrings.scrollSpeed}: '
                '${controller.scrollSensitivity.toStringAsFixed(1)}×',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: <Widget>[
                _SensitivitySlider(
                  label: AppStrings.pointerSpeed,
                  value: controller.pointerSensitivity,
                  min: 0.5,
                  max: 2.5,
                  divisions: 8,
                  onChanged: controller.setPointerSensitivity,
                ),
                _SensitivitySlider(
                  label: AppStrings.scrollSpeed,
                  value: controller.scrollSensitivity,
                  min: 1,
                  max: 8,
                  divisions: 7,
                  onChanged: controller.setScrollSensitivity,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensitivitySlider extends StatelessWidget {
  const _SensitivitySlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 104, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.toStringAsFixed(1)}×',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '${value.toStringAsFixed(1)}×',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _PadGridPainter extends CustomPainter {
  const _PadGridPainter({
    required this.navigating,
    required this.writeMode,
  });

  final bool navigating;
  final bool writeMode;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = navigating
          ? const Color(0xFF4C78D0).withValues(alpha: 0.22)
          : writeMode
              ? const Color(0xFF647086).withValues(alpha: 0.16)
              : const Color(0xFF3A987F).withValues(alpha: 0.18)
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
      oldDelegate.navigating != navigating || oldDelegate.writeMode != writeMode;
}
