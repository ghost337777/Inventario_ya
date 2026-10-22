import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Tarjeta pequeña de resumen (valor + etiqueta).
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E7EF)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textoSuave)),
        ],
      ),
    );
  }
}
