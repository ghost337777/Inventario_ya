import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/producto.dart';
import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/producto_tile.dart';

/// PANTALLA 3: consulta y resultados (inventario, búsqueda y ventas).
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _service = InventarioService.instance;
  final _busquedaCtrl = TextEditingController();
  bool _soloBajo = false;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        backgroundColor: error ? AppColors.alerta : AppColors.exito,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _vender(Producto p) async {
    final cantidad = await showDialog<int>(
      context: context,
      builder: (_) => _VentaDialog(producto: p),
    );
    if (cantidad == null) return;
    final total = _service.vender(p, cantidad);
    _mensaje('Venta registrada: $cantidad x ${p.nombre} = ${formatoPesos(total)}');
    if (p.stockBajo && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.alerta, size: 40),
          title: const Text('Stock bajo'),
          content: Text('Quedan ${p.stock} unidades de "${p.nombre}". Es momento de reabastecer.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
        ),
      );
    }
  }

  Future<void> _eliminar(Producto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${p.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.alerta),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      _service.eliminar(p.id);
      _mensaje('Producto "${p.nombre}" eliminado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Registrar producto',
        onPressed: () => Navigator.pushNamed(context, '/registro'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: CustomTextField(
              controller: _busquedaCtrl,
              label: 'Buscar producto',
              icon: Icons.search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Solo stock bajo'),
                selected: _soloBajo,
                onSelected: (v) => setState(() => _soloBajo = v),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                final lista = _service.buscar(_busquedaCtrl.text, soloStockBajo: _soloBajo);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${lista.length} productos · ventas de hoy: ${formatoPesos(_service.ventasHoy)}',
                            style: const TextStyle(color: AppColors.textoSuave, fontSize: 12)),
                      ),
                    ),
                    Expanded(
                      child: lista.isEmpty
                          ? const Center(child: Text('No se encontraron productos'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: lista.length,
                              itemBuilder: (_, i) => ProductoTile(
                                producto: lista[i],
                                onVender: () => _vender(lista[i]),
                                onEliminar: () => _eliminar(lista[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VentaDialog extends StatefulWidget {
  final Producto producto;
  const _VentaDialog({required this.producto});

  @override
  State<_VentaDialog> createState() => _VentaDialogState();
}

class _VentaDialogState extends State<_VentaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final cantidad = int.tryParse(_ctrl.text) ?? 0;
    return AlertDialog(
      title: Text('Vender ${p.nombre}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Disponibles: ${p.stock} · ${formatoPesos(p.precio)} c/u'),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _ctrl,
              label: 'Cantidad',
              icon: Icons.numbers,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => Validators.cantidadVenta(v, p.stock),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Total: ${formatoPesos(p.precio * cantidad)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) Navigator.pop(context, int.parse(_ctrl.text));
          },
          child: const Text('Confirmar venta'),
        ),
      ],
    );
  }
}
