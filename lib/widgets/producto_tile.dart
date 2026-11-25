import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'custom_card.dart';

/// Fila de producto: muestra stock en rojo cuando está bajo el mínimo.
class ProductoTile extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;

  const ProductoTile({super.key, required this.producto, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bajo = producto.stockBajo;
    final color = bajo ? AppColors.alerta : AppColors.exito;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: CustomCard(
        accent: color,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '${producto.categoria} · ${formatoPesos(producto.precio)}'
                    '${producto.perecedero ? ' · Perecedero' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textoSuave),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bajo ? 'Stock: ${producto.stock} (bajo, mínimo ${producto.stockMinimo})' : 'Stock: ${producto.stock}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textoSuave),
          ],
        ),
      ),
    );
  }
}
