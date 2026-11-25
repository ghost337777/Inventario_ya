import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../models/venta.dart';
import '../services/auth_service.dart';
import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/errores.dart';
import '../utils/formatters.dart';
import '../utils/mensajes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/sync_badge.dart';

/// PANTALLA 1: inicio (panel principal con datos de Firestore).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService.instance;
  late final Stream<ListaSync<Producto>> _productos;
  late final Stream<List<Venta>> _ventas;
  late final Stream<String> _tienda;

  @override
  void initState() {
    super.initState();
    _productos = InventarioService.instance.productosStream();
    _ventas = InventarioService.instance.ventasStream();
    _tienda = _auth.tiendaStream();
  }

  Future<void> _cerrarSesion() async {
    final ok = await confirmar(context,
        titulo: 'Cerrar sesión', mensaje: '¿Quieres salir de tu cuenta?', aceptar: 'Cerrar sesión');
    if (!ok) return;
    await _auth.cerrarSesion();
    // AuthGate detecta el cambio y vuelve a la pantalla de inicio de sesión.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InventarioYa', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: _cerrarSesion),
        ],
      ),
      body: StreamBuilder<ListaSync<Producto>>(
        stream: _productos,
        builder: (context, snapP) {
          if (snapP.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(mensajeError(snapP.error!))));
          }
          if (!snapP.hasData) return const Center(child: CircularProgressIndicator());
          final datos = snapP.data!;
          final productos = datos.items;
          final alertas = productos.where((p) => p.stockBajo).toList();
          final valorInventario = productos.fold<int>(0, (s, p) => s + p.valorTotal);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<String>(
                  stream: _tienda,
                  builder: (context, s) => Text(
                    (s.data ?? '').isEmpty ? 'Bienvenido' : s.data!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(_auth.usuario?.email ?? '', style: const TextStyle(color: AppColors.textoSuave)),
                const SizedBox(height: 8),
                SyncBadge(pendiente: datos.pendiente, desdeCache: datos.desdeCache),
                const SizedBox(height: 16),
                StreamBuilder<List<Venta>>(
                  stream: _ventas,
                  builder: (context, snapV) {
                    final hoy = (snapV.data ?? []).where((v) => v.esDeHoy);
                    final total = hoy.fold<int>(0, (s, v) => s + v.total);
                    return CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ventas de hoy', style: TextStyle(color: AppColors.textoSuave)),
                          Text(formatoPesos(total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          Text('${hoy.length} ventas registradas', style: const TextStyle(color: AppColors.textoSuave)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text('Resumen rápido', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: StatCard(
                            value: '${productos.length}', label: 'Productos', icon: Icons.inventory_2_outlined)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        value: '${alertas.length}',
                        label: 'Stock bajo',
                        icon: Icons.warning_amber_rounded,
                        color: alertas.isEmpty ? AppColors.exito : AppColors.alerta,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        value: formatoPesos(valorInventario),
                        label: 'Valor inventario',
                        icon: Icons.attach_money,
                        color: AppColors.exito,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Alertas de inventario', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (productos.isEmpty)
                  const CustomCard(child: Text('Aún no tienes productos. Registra el primero.'))
                else if (alertas.isEmpty)
                  const CustomCard(
                    accent: AppColors.exito,
                    child: Text('Todo en orden: no hay productos con stock bajo.'),
                  )
                else
                  ...alertas.map(
                    (p) => InkWell(
                      onTap: () => Navigator.pushNamed(context, '/detalle', arguments: p.id),
                      child: CustomCard(
                        accent: AppColors.alerta,
                        child: Text('${p.nombre} - quedan ${p.stock} uds',
                            style: const TextStyle(color: AppColors.alerta)),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Registrar producto',
                  icon: Icons.add_box_outlined,
                  onPressed: () => Navigator.pushNamed(context, '/registro'),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Consultar inventario',
                  icon: Icons.search,
                  outlined: true,
                  onPressed: () => Navigator.pushNamed(context, '/inventario'),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Ventas y caja del día',
                  icon: Icons.point_of_sale,
                  outlined: true,
                  color: AppColors.exito,
                  onPressed: () => Navigator.pushNamed(context, '/ventas'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
