import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/errores.dart';
import '../utils/formatters.dart';
import '../utils/mensajes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/venta_dialog.dart';
import 'ventas_screen.dart';

/// PANTALLA 4: detalle de un producto. Escucha el documento en tiempo real,
/// así que cualquier cambio en Firestore se ve de inmediato.
class DetalleScreen extends StatefulWidget {
  final String productoId;
  const DetalleScreen({super.key, required this.productoId});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  late final Stream<Producto?> _stream;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _stream = InventarioService.instance.productoStream(widget.productoId);
  }

  Future<void> _eliminar(Producto p) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar producto',
      mensaje: '¿Seguro que quieres eliminar "${p.nombre}"? Se borrará de la base de datos y no se puede deshacer.',
      aceptar: 'Eliminar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    setState(() => _eliminando = true);
    try {
      await InventarioService.instance.eliminar(p.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Producto "${p.nombre}" eliminado de la base de datos');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      mostrarMensaje(context, mensajeError(e), error: true);
    }
  }

  Future<void> _vender(Producto p) async {
    final sel = await showDialog<VentaSeleccion>(context: context, builder: (_) => VentaDialog(producto: p));
    if (sel != null && mounted) await registrarVenta(context, sel);
  }

  String _fecha(DateTime? f) {
    if (f == null) return 'Pendiente de sincronizar';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }

  Widget _fila(String etiqueta, String valor, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(etiqueta, style: const TextStyle(color: AppColors.textoSuave))),
            Expanded(child: Text(valor, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: StreamBuilder<Producto?>(
        stream: _stream,
        builder: (context, snap) {
          if (_eliminando) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(mensajeError(snap.error!))));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          if (p == null) {
            return const Center(child: Text('Este producto ya no existe en la base de datos.'));
          }
          final color = p.stockBajo ? AppColors.alerta : AppColors.exito;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(p.categoria, style: const TextStyle(color: AppColors.textoSuave)),
                const SizedBox(height: 16),
                CustomCard(
                  accent: color,
                  child: Column(
                    children: [
                      _fila('Precio', formatoPesos(p.precio)),
                      _fila('Stock actual', '${p.stock} unidades', color: color),
                      _fila('Alerta en', '${p.stockMinimo} unidades'),
                      _fila('Estado', p.stockBajo ? 'Stock bajo: reabastecer' : 'Stock suficiente', color: color),
                      _fila('Perecedero', p.perecedero ? 'Sí' : 'No'),
                      _fila('Valor en bodega', formatoPesos(p.valorTotal)),
                    ],
                  ),
                ),
                CustomCard(
                  accent: AppColors.textoSuave,
                  child: Column(
                    children: [
                      _fila('ID en Firestore', p.id),
                      _fila('Creado', _fecha(p.creadoEn)),
                      _fila('Última edición', _fecha(p.actualizadoEn)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Registrar venta',
                  icon: Icons.shopping_cart_outlined,
                  color: AppColors.exito,
                  onPressed: p.stock == 0 ? null : () => _vender(p),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Editar producto',
                  icon: Icons.edit_outlined,
                  outlined: true,
                  onPressed: () => Navigator.pushNamed(context, '/editar', arguments: p),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Eliminar producto',
                  icon: Icons.delete_outline,
                  outlined: true,
                  color: AppColors.alerta,
                  onPressed: () => _eliminar(p),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
