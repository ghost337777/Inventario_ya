import 'package:flutter/material.dart';

import 'app_theme.dart';

/// SnackBar verde (éxito) o rojo (error).
void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.alerta : AppColors.exito,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Diálogo de confirmación. Devuelve true solo si el usuario acepta.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String aceptar = 'Aceptar',
  bool peligroso = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: peligroso ? FilledButton.styleFrom(backgroundColor: AppColors.alerta) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(aceptar),
        ),
      ],
    ),
  );
  return r == true;
}

/// Aviso de stock bajo después de una venta o un registro.
Future<void> avisoStockBajo(BuildContext context, String nombre, int stock, int minimo) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.alerta, size: 40),
      title: const Text('Stock bajo'),
      content: Text('Quedan $stock unidades de "$nombre" (mínimo $minimo). Es momento de reabastecer.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
    ),
  );
}
