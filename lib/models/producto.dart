/// Modelo de un producto del inventario de la tienda.
class Producto {
  final String id;
  final String nombre;
  final String categoria;
  final int precio; // COP
  int stock;
  final int stockMinimo;
  final bool perecedero;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    this.perecedero = false,
  });

  /// Un producto está en alerta cuando su stock llegó al mínimo definido.
  bool get stockBajo => stock <= stockMinimo;

  int get valorTotal => precio * stock;
}
