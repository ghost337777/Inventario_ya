import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de un producto del inventario (colección "productos" en Firestore).
class Producto {
  final String id;
  final String uid; // dueño del registro (usuario autenticado)
  final String nombre;
  final String categoria;
  final int precio; // COP
  final int stock;
  final int stockMinimo;
  final bool perecedero;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Producto({
    this.id = '',
    this.uid = '',
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    this.perecedero = false,
    this.creadoEn,
    this.actualizadoEn,
  });

  /// Un producto está en alerta cuando su stock llegó al mínimo definido.
  bool get stockBajo => stock <= stockMinimo;

  int get valorTotal => precio * stock;

  /// Firestore -> App
  factory Producto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Producto(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      nombre: d['nombre'] as String? ?? '',
      categoria: d['categoria'] as String? ?? 'Otros',
      precio: (d['precio'] as num?)?.toInt() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
      stockMinimo: (d['stockMinimo'] as num?)?.toInt() ?? 1,
      perecedero: d['perecedero'] as bool? ?? false,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
      actualizadoEn: (d['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }

  /// App -> Firestore (campos editables por el usuario)
  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'nombreLower': nombre.toLowerCase(),
        'categoria': categoria,
        'precio': precio,
        'stock': stock,
        'stockMinimo': stockMinimo,
        'perecedero': perecedero,
      };
}
