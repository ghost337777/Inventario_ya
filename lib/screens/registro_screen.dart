import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/producto.dart';
import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/producto_tile.dart';

/// PANTALLA 2: registro de información (formulario de producto).
/// Controles usados: TextFormField, DropdownButton, Slider, Switch y Checkbox.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  static const _categorias = ['Granos', 'Abarrotes', 'Aseo', 'Lácteos y huevos', 'Bebidas', 'Papelería', 'Otros'];

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _service = InventarioService.instance;

  String? _categoria;
  double _stockMinimo = 5;
  bool _perecedero = false;
  bool _confirmo = false;
  String? _errorConfirmo;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
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

  void _limpiar() {
  _nombreCtrl.clear();
  _precioCtrl.clear();
  _stockCtrl.clear();
  _formKey.currentState?.reset();
  setState(() {
    _categoria = null;
    _stockMinimo = 5;
    _perecedero = false;
    _confirmo = false;
    _errorConfirmo = null;
  });
}

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      _mensaje('Corrige los campos marcados en rojo', error: true);
      return;
    }
    if (!_confirmo) {
      setState(() => _errorConfirmo = 'Debes confirmar que los datos son correctos');
      return;
    }
    if (_service.existeNombre(_nombreCtrl.text)) {
      _mensaje('Ya existe un producto con ese nombre', error: true);
      return;
    }

    final producto = Producto(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoria!,
      precio: int.parse(_precioCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
      stockMinimo: _stockMinimo.round(),
      perecedero: _perecedero,
    );
    _service.agregar(producto);
    _mensaje('Producto "${producto.nombre}" registrado correctamente');
    _limpiar();

    if (producto.stockBajo) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.alerta, size: 40),
          title: const Text('Stock bajo'),
          content: Text('"${producto.nombre}" quedó con ${producto.stock} unidades, '
              'igual o por debajo del mínimo (${producto.stockMinimo}). Considera reabastecer.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre del producto',
                    hint: 'Ej: Arroz Diana 1kg',
                    icon: Icons.label_outline,
                    validator: Validators.nombre,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)),
                    items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _categoria = v),
                    validator: (v) => v == null ? 'Selecciona una categoría' : null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _precioCtrl,
                          label: 'Precio',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: Validators.precio,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _stockCtrl,
                          label: 'Stock',
                          icon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: Validators.stock,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Alerta de stock bajo en: ${_stockMinimo.round()} unidades',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _stockMinimo,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: _stockMinimo.round().toString(),
                    onChanged: (v) => setState(() => _stockMinimo = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Producto perecedero'),
                    subtitle: const Text('Se vence o se daña con el tiempo'),
                    value: _perecedero,
                    onChanged: (v) => setState(() => _perecedero = v),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Confirmo que los datos son correctos'),
                    subtitle: _errorConfirmo == null
                        ? null
                        : Text(_errorConfirmo!, style: const TextStyle(color: AppColors.alerta)),
                    value: _confirmo,
                    onChanged: (v) => setState(() {
                      _confirmo = v ?? false;
                      _errorConfirmo = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  CustomButton(text: 'Guardar producto', icon: Icons.save_outlined, onPressed: _guardar),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Limpiar formulario',
                    icon: Icons.refresh,
                    outlined: true,
                    color: AppColors.textoSuave,
                    onPressed: _limpiar,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Últimos productos registrados', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                final ultimos = _service.productos.reversed.take(3).toList();
                return Column(children: ultimos.map((p) => ProductoTile(producto: p)).toList());
              },
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Ir al inventario',
              icon: Icons.list_alt,
              outlined: true,
              onPressed: () => Navigator.pushNamed(context, '/inventario'),
            ),
          ],
        ),
      ),
    );
  }
}
