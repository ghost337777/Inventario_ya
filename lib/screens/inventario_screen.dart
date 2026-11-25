import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/errores.dart';
import '../utils/mensajes.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/producto_tile.dart';
import '../widgets/sync_badge.dart';

/// PANTALLA 2: consulta / listado de los productos guardados en Firestore.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _service = InventarioService.instance;
  final _busquedaCtrl = TextEditingController();
  late final Stream<ListaSync<Producto>> _stream;
  bool _soloBajo = false;

  @override
  void initState() {
    super.initState();
    _stream = _service.productosStream();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(List<Producto> todos) {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    return todos.where((p) {
      final coincide = q.isEmpty || p.nombre.toLowerCase().contains(q) || p.categoria.toLowerCase().contains(q);
      return coincide && (!_soloBajo || p.stockBajo);
    }).toList();
  }

  Future<void> _recargar() async {
    try {
      final n = await _service.recargarDesdeServidor();
      if (mounted) mostrarMensaje(context, 'Datos recargados desde el servidor ($n productos)');
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.sync), onPressed: _recargar)],
      ),
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
              label: 'Buscar producto o categoría',
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
            child: StreamBuilder<ListaSync<Producto>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                      child: Padding(padding: const EdgeInsets.all(24), child: Text(mensajeError(snap.error!))));
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final lista = _filtrar(snap.data!.items);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${lista.length} de ${snap.data!.items.length} productos',
                                style: const TextStyle(color: AppColors.textoSuave, fontSize: 12)),
                          ),
                          SyncBadge(pendiente: snap.data!.pendiente, desdeCache: snap.data!.desdeCache),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _recargar,
                        child: lista.isEmpty
                            ? ListView(children: const [
                                SizedBox(height: 80),
                                Center(child: Text('No se encontraron productos')),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                                itemCount: lista.length,
                                itemBuilder: (_, i) => ProductoTile(
                                  producto: lista[i],
                                  onTap: () => Navigator.pushNamed(context, '/detalle', arguments: lista[i].id),
                                ),
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
