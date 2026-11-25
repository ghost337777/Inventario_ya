import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/inventario_service.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';
import '../widgets/custom_button.dart';
import '../widgets/producto_form.dart';

/// PANTALLA 3: registro de un producto nuevo en Firestore.
class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  Future<bool> _guardar(BuildContext context, Producto p) async {
    final service = InventarioService.instance;
    try {
      if (await service.existeNombre(p.nombre)) {
        if (context.mounted) mostrarMensaje(context, 'Ya existe un producto con ese nombre', error: true);
        return false;
      }
      await service.crear(p);
      if (!context.mounted) return true;
      mostrarMensaje(context, 'Producto "${p.nombre}" guardado en la base de datos');
      if (p.stockBajo) await avisoStockBajo(context, p.nombre, p.stock, p.stockMinimo);
      return true;
    } catch (e) {
      if (context.mounted) mostrarMensaje(context, mensajeError(e), error: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProductoForm(
              textoBoton: 'Guardar producto',
              onGuardar: (p) => _guardar(context, p),
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Ir al inventario',
              icon: Icons.list_alt,
              outlined: true,
              onPressed: () => Navigator.pushReplacementNamed(context, '/inventario'),
            ),
          ],
        ),
      ),
    );
  }
}
