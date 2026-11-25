import 'dart:async';

import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../models/venta.dart';
import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/errores.dart';
import '../utils/formatters.dart';
import '../utils/mensajes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/venta_dialog.dart';

/// Registra la venta en Firestore y muestra el resultado al usuario.
/// La usan la pantalla de Ventas y la de Detalle.
Future<void> registrarVenta(BuildContext context, VentaSeleccion sel) async {
  try {
    final actualizado = await InventarioService.instance.vender(sel.producto.id, sel.cantidad);
    if (!context.mounted) return;
    mostrarMensaje(context,
        'Venta registrada: ${sel.cantidad} x ${sel.producto.nombre} = ${formatoPesos(sel.producto.precio * sel.cantidad)}');
    if (actualizado.stockBajo) {
      await avisoStockBajo(context, actualizado.nombre, actualizado.stock, actualizado.stockMinimo);
    }
  } catch (e) {
    if (context.mounted) mostrarMensaje(context, mensajeError(e), error: true);
  }
}

/// PANTALLA 6 (funcionalidad principal): ventas y caja del día.
/// Cada venta descuenta stock y se guarda en la colección "ventas".
class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _service = InventarioService.instance;
  late final StreamSubscription<ListaSync<Producto>> _subProductos;
  late final Stream<List<Venta>> _ventas;
  List<Producto> _ultimosProductos = const [];
  bool _soloHoy = true;

  @override
  void initState() {
    super.initState();
    _ventas = _service.ventasStream();
    _subProductos = _service.productosStream().listen((d) => _ultimosProductos = d.items, onError: (_) {});
  }

  @override
  void dispose() {
    _subProductos.cancel();
    super.dispose();
  }

  Future<void> _nuevaVenta() async {
    if (_ultimosProductos.every((p) => p.stock == 0)) {
      mostrarMensaje(context, 'No hay productos con stock para vender', error: true);
      return;
    }
    final sel = await showDialog<VentaSeleccion>(
      context: context,
      builder: (_) => VentaDialog(productos: _ultimosProductos),
    );
    if (sel != null && mounted) await registrarVenta(context, sel);
  }

  String _hora(DateTime f) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return _soloHoy ? '${dos(f.hour)}:${dos(f.minute)}' : '${dos(f.day)}/${dos(f.month)} ${dos(f.hour)}:${dos(f.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas y caja del día')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaVenta,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva venta'),
      ),
      body: StreamBuilder<List<Venta>>(
        stream: _ventas,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(mensajeError(snap.error!))));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final todas = snap.data!;
          final hoy = todas.where((v) => v.esDeHoy).toList();
          final lista = _soloHoy ? hoy : todas;
          final totalHoy = hoy.fold<int>(0, (s, v) => s + v.total);
          final unidadesHoy = hoy.fold<int>(0, (s, v) => s + v.cantidad);

          // Producto más vendido del día
          final porProducto = <String, int>{};
          for (final v in hoy) {
            porProducto[v.productoNombre] = (porProducto[v.productoNombre] ?? 0) + v.cantidad;
          }
          final top = porProducto.entries.isEmpty
              ? null
              : porProducto.entries.reduce((a, b) => a.value >= b.value ? a : b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              CustomCard(
                accent: AppColors.exito,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Caja de hoy', style: TextStyle(color: AppColors.textoSuave)),
                    Text(formatoPesos(totalHoy), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(child: StatCard(value: '${hoy.length}', label: 'Ventas hoy', icon: Icons.receipt_long)),
                  const SizedBox(width: 8),
                  Expanded(child: StatCard(value: '$unidadesHoy', label: 'Unidades', icon: Icons.shopping_bag_outlined)),
                ],
              ),
              const SizedBox(height: 8),
              if (top != null)
                CustomCard(
                  child: Text('Más vendido hoy: ${top.key} (${top.value} uds)',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Historial', style: TextStyle(fontWeight: FontWeight.bold))),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Hoy')),
                      ButtonSegment(value: false, label: Text('Todas')),
                    ],
                    selected: {_soloHoy},
                    onSelectionChanged: (s) => setState(() => _soloHoy = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (lista.isEmpty)
                const CustomCard(child: Text('No hay ventas registradas.'))
              else
                ...lista.map(
                  (v) => CustomCard(
                    accent: AppColors.primary,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${v.cantidad} x ${formatoPesos(v.precioUnitario)} · ${_hora(v.fecha)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textoSuave)),
                            ],
                          ),
                        ),
                        Text(formatoPesos(v.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Ver inventario',
                icon: Icons.inventory_2_outlined,
                outlined: true,
                onPressed: () => Navigator.pushNamed(context, '/inventario'),
              ),
            ],
          );
        },
      ),
    );
  }
}
