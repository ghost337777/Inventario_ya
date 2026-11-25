import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/producto.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'custom_text_field.dart';

/// Resultado del diálogo: qué producto y cuántas unidades vender.
class VentaSeleccion {
  final Producto producto;
  final int cantidad;
  const VentaSeleccion(this.producto, this.cantidad);
}

/// Diálogo para registrar una venta. Si se pasa [producto] queda fijo;
/// si no, el usuario lo elige de la lista [productos].
class VentaDialog extends StatefulWidget {
  final Producto? producto;
  final List<Producto> productos;

  const VentaDialog({super.key, this.producto, this.productos = const []});

  @override
  State<VentaDialog> createState() => _VentaDialogState();
}

class _VentaDialogState extends State<VentaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController(text: '1');
  Producto? _producto;

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _producto;
    final cantidad = int.tryParse(_ctrl.text) ?? 0;
    final disponibles = widget.productos.where((x) => x.stock > 0).toList();
    return AlertDialog(
      title: Text(widget.producto == null ? 'Nueva venta' : 'Vender ${widget.producto!.nombre}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.producto == null) ...[
                DropdownButtonFormField<String>(
                  initialValue: p?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Producto', prefixIcon: Icon(Icons.inventory_2_outlined)),
                  items: disponibles
                      .map((x) => DropdownMenuItem(value: x.id, child: Text('${x.nombre} (${x.stock})')))
                      .toList(),
                  onChanged: (id) => setState(() => _producto = disponibles.firstWhere((x) => x.id == id)),
                  validator: (v) => v == null ? 'Selecciona un producto' : null,
                ),
                const SizedBox(height: 12),
              ],
              if (p != null) Text('Disponibles: ${p.stock} · ${formatoPesos(p.precio)} c/u'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _ctrl,
                label: 'Cantidad',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => p == null ? null : Validators.cantidadVenta(v, p.stock),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text('Total: ${formatoPesos((p?.precio ?? 0) * cantidad)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _producto != null) {
              Navigator.pop(context, VentaSeleccion(_producto!, int.parse(_ctrl.text)));
            }
          },
          child: const Text('Confirmar venta'),
        ),
      ],
    );
  }
}
