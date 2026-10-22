import 'package:flutter/foundation.dart';

import '../models/producto.dart';

/// Gestiona el inventario EN MEMORIA (sin base de datos, API ni persistencia).
/// Notifica a la interfaz cada vez que cambian los datos.
class InventarioService extends ChangeNotifier {
  InventarioService._();
  static final InventarioService instance = InventarioService._();

  int _ventasHoy = 342500;

  final List<Producto> _productos = [
    Producto(id: '1', nombre: 'Arroz Diana 1kg', categoria: 'Granos', precio: 4800, stock: 3, stockMinimo: 5),
    Producto(id: '2', nombre: 'Aceite Gourmet 1L', categoria: 'Abarrotes', precio: 12500, stock: 2, stockMinimo: 4),
    Producto(id: '3', nombre: 'Panela x libra', categoria: 'Abarrotes', precio: 3200, stock: 40, stockMinimo: 10),
    Producto(id: '4', nombre: 'Jabón Rey', categoria: 'Aseo', precio: 2500, stock: 25, stockMinimo: 8),
    Producto(id: '5', nombre: 'Café Águila 500g', categoria: 'Abarrotes', precio: 14900, stock: 18, stockMinimo: 6),
    Producto(id: '6', nombre: 'Huevos AA x30', categoria: 'Lácteos y huevos', precio: 19800, stock: 12, stockMinimo: 5, perecedero: true),
  ];

  List<Producto> get productos => List.unmodifiable(_productos);
  int get ventasHoy => _ventasHoy;
  int get totalProductos => _productos.length;
  List<Producto> get productosStockBajo => _productos.where((p) => p.stockBajo).toList();
  int get valorInventario => _productos.fold(0, (suma, p) => suma + p.valorTotal);

  bool existeNombre(String nombre) =>
      _productos.any((p) => p.nombre.toLowerCase() == nombre.trim().toLowerCase());

  List<Producto> buscar(String texto, {bool soloStockBajo = false}) {
    final q = texto.trim().toLowerCase();
    return _productos.where((p) {
      final coincide = q.isEmpty || p.nombre.toLowerCase().contains(q) || p.categoria.toLowerCase().contains(q);
      return coincide && (!soloStockBajo || p.stockBajo);
    }).toList();
  }

  void agregar(Producto producto) {
    _productos.add(producto);
    notifyListeners();
  }

  /// Procesa una venta: descuenta stock y acumula el total vendido.
  /// Devuelve el valor de la venta.
  int vender(Producto producto, int cantidad) {
    producto.stock -= cantidad;
    final total = producto.precio * cantidad;
    _ventasHoy += total;
    notifyListeners();
    return total;
  }

  void eliminar(String id) {
    _productos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
