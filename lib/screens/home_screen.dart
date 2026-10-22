import 'package:flutter/material.dart';

import '../services/inventario_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/stat_card.dart';

/// PANTALLA 1: principal (dashboard).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = InventarioService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('InventarioYa', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final alertas = service.productosStockBajo;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bienvenido, Sebastian', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('Tienda La Esquina', style: TextStyle(color: AppColors.textoSuave)),
                const SizedBox(height: 16),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ventas de hoy', style: TextStyle(color: AppColors.textoSuave)),
                      Text(formatoPesos(service.ventasHoy),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Resumen rápido', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: StatCard(value: '${service.totalProductos}', label: 'Productos', icon: Icons.inventory_2_outlined)),
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
                        value: formatoPesos(service.valorInventario),
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
                if (alertas.isEmpty)
                  const CustomCard(
                    accent: AppColors.exito,
                    child: Text('Todo en orden: no hay productos con stock bajo.'),
                  )
                else
                  ...alertas.map(
                    (p) => CustomCard(
                      accent: AppColors.alerta,
                      child: Text('${p.nombre} - quedan ${p.stock} uds',
                          style: const TextStyle(color: AppColors.alerta)),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
