import 'package:flutter/material.dart';

class CanvasSurface extends StatelessWidget {
  const CanvasSurface({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E7EF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080D1830),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
