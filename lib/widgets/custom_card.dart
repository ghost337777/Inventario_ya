import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Contenedor reutilizable con borde de acento a la izquierda.
class CustomCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsets padding;

  const CustomCard({
    super.key,
    required this.child,
    this.accent = AppColors.primary,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 5)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: padding,
      child: child,
    );
  }
}
