import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria.dart';
import '../models/producto.dart';
import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';
import '../utils/validators.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

/// COMPONENTE REUTILIZABLE: formulario de producto.
/// Lo usan la pantalla de Registro (vacío) y la de Edición (con datos).
/// Controles: TextFormField, Dropdown, Slider, Switch y Checkbox.
class ProductoForm extends StatefulWidget {
  final Producto? inicial;
  final String textoBoton;
  final bool pedirConfirmacion;

  /// Guarda el producto. Devuelve true si se guardó (para limpiar el formulario).
  final Future<bool> Function(Producto producto) onGuardar;

  const ProductoForm({
    super.key,
    this.inicial,
    required this.textoBoton,
    required this.onGuardar,
    this.pedirConfirmacion = true,
  });

  @override
  State<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockCtrl;
  late final Stream<List<Categoria>> _categoriasStream;

  String? _categoria;
  double _stockMinimo = 5;
  bool _perecedero = false;
  bool _confirmo = false;
  String? _errorConfirmo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.inicial;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _precioCtrl = TextEditingController(text: p == null ? '' : '${p.precio}');
    _stockCtrl = TextEditingController(text: p == null ? '' : '${p.stock}');
    _categoria = p?.categoria;
    _stockMinimo = (p?.stockMinimo ?? 5).clamp(1, 20).toDouble();
    _perecedero = p?.perecedero ?? false;
    _categoriasStream = InventarioService.instance.categoriasStream();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
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

  Future<void> _nuevaCategoria() async {
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    if (nombre == null || nombre.length < 3) return;
    try {
      await InventarioService.instance.crearCategoria(nombre);
      if (!mounted) return;
      setState(() => _categoria = nombre);
      mostrarMensaje(context, 'Categoría "$nombre" guardada en la nube');
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeError(e), error: true);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      mostrarMensaje(context, 'Corrige los campos marcados en rojo', error: true);
      return;
    }
    if (widget.pedirConfirmacion && !_confirmo) {
      setState(() => _errorConfirmo = 'Debes confirmar que los datos son correctos');
      return;
    }
    final producto = Producto(
      id: widget.inicial?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoria!,
      precio: int.parse(_precioCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
      stockMinimo: _stockMinimo.round(),
      perecedero: _perecedero,
    );
    setState(() => _guardando = true);
    final ok = await widget.onGuardar(producto);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok && widget.inicial == null) _limpiar();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
          StreamBuilder<List<Categoria>>(
            stream: _categoriasStream,
            builder: (context, snap) {
              final nombres = (snap.data ?? []).map((c) => c.nombre).toSet();
              if (_categoria != null) nombres.add(_categoria!);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('cat-$_categoria-${nombres.length}'),
                      initialValue: _categoria,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: const Icon(Icons.category_outlined),
                        helperText: snap.hasData ? null : 'Cargando categorías…',
                      ),
                      items: nombres.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _categoria = v),
                      validator: (v) => v == null ? 'Selecciona una categoría' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Nueva categoría',
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: _nuevaCategoria,
                  ),
                ],
              );
            },
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
          if (widget.pedirConfirmacion)
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
          _guardando
              ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
              : CustomButton(text: widget.textoBoton, icon: Icons.cloud_upload_outlined, onPressed: _guardar),
          if (widget.inicial == null) ...[
            const SizedBox(height: 10),
            CustomButton(
              text: 'Limpiar formulario',
              icon: Icons.refresh,
              outlined: true,
              color: AppColors.textoSuave,
              onPressed: _limpiar,
            ),
          ],
        ],
      ),
    );
  }
}
