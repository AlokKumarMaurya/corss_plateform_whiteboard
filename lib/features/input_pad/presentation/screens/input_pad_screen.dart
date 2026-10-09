import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/input_pad/presentation/controllers/input_pad_controller.dart';
import 'package:cross_platform_whiteboard/features/session/data/services/realtime_session_service.dart';
import 'package:cross_platform_whiteboard/features/session/domain/models/session_status.dart';
import 'package:cross_platform_whiteboard/features/session/presentation/widgets/session_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InputPadScreen extends GetView<InputPadController> {
  const InputPadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RealtimeSessionService session = Get.find<RealtimeSessionService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
        actions: <Widget>[
          Obx(() {
            if (session.status.value != SessionStatus.connected) {
              return const SizedBox.shrink();
            }
            return TextButton.icon(
              onPressed: session.disconnect,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text(AppStrings.actionDisconnectSession),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _InputPadControls(controller: controller),
              Obx(
                () => session.status.value == SessionStatus.connected
                    ? const SizedBox.shrink()
                    : const SessionPanel(),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF171B24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF303746)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      controller.setPadSize(
                        Size(constraints.maxWidth, constraints.maxHeight),
                      );
                      return Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: controller.pointerDown,
                        onPointerMove: controller.pointerMove,
                        onPointerHover: controller.pointerHover,
                        onPointerUp: controller.pointerUp,
                        onPointerCancel: controller.pointerCancel,
                        child: Obx(
                          () => CustomPaint(
                            painter: _PadGridPainter(
                              navigating: controller.isNavigating,
                              writeMode: controller.writeMode,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Obx(
              () => SegmentedButton<bool>(
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
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: AppStrings.inputSettings,
            onPressed: () => _showInputSettings(context, controller),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  void _showInputSettings(
    BuildContext context,
    InputPadController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    AppStrings.inputSettings,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.pointerMappingMode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.touchpad_mouse_rounded),
                        label: Text(AppStrings.trackpadMode),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.tablet_mac_rounded),
                        label: Text(AppStrings.tabletMode),
                      ),
                    ],
                    selected: <bool>{controller.tabletMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<bool> selection) {
                      controller.setTabletMode(selection.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.tabletMode
                        ? AppStrings.tabletModeHint
                        : AppStrings.trackpadModeHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
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
                    max: 14,
                    divisions: 13,
                    onChanged: controller.setScrollSensitivity,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
