import 'package:flutter/material.dart';

class ToolButton extends StatelessWidget {
  const ToolButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        tooltip: label,
        isSelected: selected,
        style: IconButton.styleFrom(
          foregroundColor: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF566074),
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
