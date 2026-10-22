import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// COMPONENTE PERSONALIZADO 2: botón reutilizable (relleno o con borde).
class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final Color color;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const padding = EdgeInsets.symmetric(vertical: 14);

    final Widget button = outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon ?? Icons.arrow_forward, size: 20),
            label: label,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: shape,
              padding: padding,
            ),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon ?? Icons.check, size: 20),
            label: label,
            style: FilledButton.styleFrom(backgroundColor: color, shape: shape, padding: padding),
          );
    return SizedBox(width: double.infinity, child: button);
  }
}
