import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/inventario_service.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';
import '../widgets/producto_form.dart';

/// PANTALLA 5: edición de un producto existente (update en Firestore).
class EditarScreen extends StatelessWidget {
  final Producto producto;
  const EditarScreen({super.key, required this.producto});

  Future<bool> _guardar(BuildContext context, Producto cambios) async {
    final service = InventarioService.instance;
    try {
      if (await service.existeNombre(cambios.nombre, excluirId: producto.id)) {
        if (context.mounted) mostrarMensaje(context, 'Ya existe otro producto con ese nombre', error: true);
        return false;
      }
      await service.actualizar(cambios);
      if (!context.mounted) return true;
      mostrarMensaje(context, 'Cambios guardados en la base de datos');
      Navigator.pop(context);
      return true;
    } catch (e) {
      if (context.mounted) mostrarMensaje(context, mensajeError(e), error: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ProductoForm(
          inicial: producto,
          textoBoton: 'Guardar cambios',
          pedirConfirmacion: false,
          onGuardar: (p) => _guardar(context, p),
        ),
      ),
    );
  }
}
