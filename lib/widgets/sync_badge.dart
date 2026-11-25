import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Indicador del estado de sincronización con Firestore.
/// - Pendiente: hay cambios en el celular que aún no llegan al servidor.
/// - Sin conexión: se muestran datos de la caché local.
/// - Sincronizado: los datos coinciden con la base de datos remota.
class SyncBadge extends StatelessWidget {
  final bool pendiente;
  final bool desdeCache;

  const SyncBadge({super.key, required this.pendiente, required this.desdeCache});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String texto, Color color) = pendiente
        ? (Icons.cloud_upload_outlined, 'Sincronizando…', Colors.orange.shade800)
        : desdeCache
            ? (Icons.cloud_off_outlined, 'Sin conexión (caché)', AppColors.textoSuave)
            : (Icons.cloud_done_outlined, 'Sincronizado', AppColors.exito);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
