import 'package:cross_platform_whiteboard/core/constants/drawing_constants.dart';
import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/drawing/domain/models/drawing_tool.dart';
import 'package:cross_platform_whiteboard/features/drawing/presentation/widgets/drawing_canvas.dart';
import 'package:cross_platform_whiteboard/features/whiteboard/presentation/controllers/whiteboard_controller.dart';
import 'package:cross_platform_whiteboard/shared/widgets/canvas_surface.dart';
import 'package:cross_platform_whiteboard/shared/widgets/section_label.dart';
import 'package:cross_platform_whiteboard/shared/widgets/tool_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhiteboardScreen extends GetView<WhiteboardController> {
  const WhiteboardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const _BrandTitle(),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Obx(
                () => _StatusPill(
                  label: controller.isEmpty
                      ? AppStrings.statusReady
                      : AppStrings.statusDrawing,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _PageHeading(),
                const SizedBox(height: 20),
                const _Toolbar(),
                const SizedBox(height: 14),
                Expanded(
                  child: CanvasSurface(
                    child: DrawingCanvas(controller: controller),
                  ),
                ),
                const SizedBox(height: 10),
                const _FooterHint(),
              ],
            ),
          ),
        ),
      );
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.gesture_rounded, size: 26),
          SizedBox(width: 10),
          Text(AppStrings.appName),
        ],
      );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.whiteboardTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF172033),
                        letterSpacing: -0.7,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.whiteboardSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF697386),
                      ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _showPairingPlaceholder,
            icon: const Icon(Icons.phonelink_ring_rounded),
            label: const Text(AppStrings.actionConnectPhone),
          ),
        ],
      );

  void _showPairingPlaceholder() => Get.snackbar(
        AppStrings.titlePhoneConnection,
        AppStrings.actionComingSoon,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
}

class _Toolbar extends GetView<WhiteboardController> {
  const _Toolbar();

  @override
  Widget build(BuildContext context) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          const SectionLabel(AppStrings.sectionTools),
          Obx(
            () => ToolButton(
              label: AppStrings.toolPen,
              icon: Icons.edit_rounded,
              selected: controller.selectedTool.value == DrawingTool.pen,
              onPressed: () => controller.setTool(DrawingTool.pen),
            ),
          ),
          Obx(
            () => ToolButton(
              label: AppStrings.toolEraser,
              icon: Icons.auto_fix_normal_rounded,
              selected: controller.selectedTool.value == DrawingTool.eraser,
              onPressed: () => controller.setTool(DrawingTool.eraser),
            ),
          ),
          const SizedBox(width: 12),
          const SectionLabel(AppStrings.sectionColor),
          ..._colorOptions(),
          const SizedBox(width: 12),
          const SectionLabel(AppStrings.sectionWidth),
          SizedBox(
            width: 140,
            child: Obx(
              () => Slider(
                min: DrawingConstants.minimumStrokeWidth,
                max: DrawingConstants.maximumStrokeWidth,
                value: controller.strokeWidth.value,
                onChanged: controller.setStrokeWidth,
              ),
            ),
          ),
          Obx(
            () => ToolButton(
              label: AppStrings.actionUndo,
              icon: Icons.undo_rounded,
              enabled: controller.canUndo,
              onPressed: controller.undo,
            ),
          ),
          Obx(
            () => ToolButton(
              label: AppStrings.actionRedo,
              icon: Icons.redo_rounded,
              enabled: controller.canRedo,
              onPressed: controller.redo,
            ),
          ),
          ToolButton(
            label: AppStrings.actionClear,
            icon: Icons.delete_outline_rounded,
            onPressed: _confirmClear,
          ),
        ],
      );

  List<Widget> _colorOptions() => <Color>[
        const Color(0xFF172033),
        const Color(0xFF3157D5),
        const Color(0xFFE5484D),
        const Color(0xFF1D9A70),
      ]
          .map(
            (Color color) => Obx(
              () => _ColorDot(
                color: color,
                selected: controller.selectedColorValue.value == color.value,
                label: _colorName(color),
                onTap: () => controller.setColor(color),
              ),
            ),
          )
          .toList(growable: false);

  String _colorName(Color color) {
    if (color == const Color(0xFF172033)) return AppStrings.colorBlack;
    if (color == const Color(0xFF3157D5)) return AppStrings.colorBlue;
    if (color == const Color(0xFFE5484D)) return AppStrings.colorRed;
    return AppStrings.colorGreen;
  }

  void _confirmClear() => Get.dialog<void>(
        AlertDialog(
          title: const Text(AppStrings.actionClearTitle),
          content: const Text(AppStrings.actionClearMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Get.back<void>(),
              child: const Text(AppStrings.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                controller.clearCanvas();
                Get.back<void>();
              },
              child: const Text(AppStrings.actionClearConfirm),
            ),
          ],
        ),
      );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected ? const Color(0xFF8292C2) : Colors.white,
                width: selected ? 3 : 1,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x10000000), blurRadius: 3),
              ],
            ),
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F7EE),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.circle, size: 8, color: Color(0xFF159957)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF16794B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _FooterHint extends StatelessWidget {
  const _FooterHint();

  @override
  Widget build(BuildContext context) => const Row(
        children: <Widget>[
          Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFF7B8495)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.statusEmpty,
              style: TextStyle(color: Color(0xFF7B8495), fontSize: 12),
            ),
          ),
        ],
      );
}
