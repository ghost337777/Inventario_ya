import 'package:cloud_firestore/cloud_firestore.dart';

/// Categoría de productos (colección "categorias" en Firestore).
class Categoria {
  final String id;
  final String nombre;

  const Categoria({required this.id, required this.nombre});

  factory Categoria.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Categoria(id: doc.id, nombre: doc.data()?['nombre'] as String? ?? '');

  static const porDefecto = ['Granos', 'Abarrotes', 'Aseo', 'Lácteos y huevos', 'Bebidas', 'Papelería', 'Otros'];
}
