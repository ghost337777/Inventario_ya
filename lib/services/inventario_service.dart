import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/categoria.dart';
import '../models/producto.dart';
import '../models/venta.dart';

/// Lista recibida desde Firestore junto con su estado de sincronización.
class ListaSync<T> {
  final List<T> items;

  /// true si hay cambios hechos en el celular que aún no llegan al servidor.
  final bool pendiente;

  /// true si los datos vienen de la caché local (sin conexión).
  final bool desdeCache;

  const ListaSync(this.items, {this.pendiente = false, this.desdeCache = false});
}

/// Persistencia REMOTA con Cloud Firestore.
/// Todas las operaciones (crear, consultar, actualizar, eliminar) se hacen
/// sobre la base de datos centralizada; ya no se usan listas en memoria.
class InventarioService {
  InventarioService._();
  static final InventarioService instance = InventarioService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productos => _db.collection('productos');
  CollectionReference<Map<String, dynamic>> get _ventas => _db.collection('ventas');
  CollectionReference<Map<String, dynamic>> get _categorias => _db.collection('categorias');

  /// UID del usuario autenticado. Cada registro se guarda con este valor y las
  /// reglas de seguridad solo dejan leer/escribir los registros propios.
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Debes iniciar sesión');
    return user.uid;
  }

  // ---------------------------------------------------------------- CONSULTAR

  /// Base de datos remota -> App, en tiempo real.
  /// Cada vez que cambia un producto en Firestore, la lista se vuelve a emitir.
  Stream<ListaSync<Producto>> productosStream() {
    return _productos
        .where('uid', isEqualTo: _uid)
        .snapshots(includeMetadataChanges: true)
        .map((snap) {
      final lista = snap.docs.map(Producto.fromDoc).toList()
        ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return ListaSync(lista, pendiente: snap.metadata.hasPendingWrites, desdeCache: snap.metadata.isFromCache);
    });
  }

  /// Un solo producto (pantalla de detalle). Emite null si fue eliminado.
  Stream<Producto?> productoStream(String id) {
    return _productos.doc(id).snapshots().map((doc) => doc.exists ? Producto.fromDoc(doc) : null);
  }

  Stream<List<Venta>> ventasStream() {
    return _ventas.where('uid', isEqualTo: _uid).snapshots().map((snap) {
      final lista = snap.docs.map(Venta.fromDoc).toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  Stream<List<Categoria>> categoriasStream() {
    return _categorias.where('uid', isEqualTo: _uid).snapshots().map((snap) {
      final lista = snap.docs.map(Categoria.fromDoc).toList()..sort((a, b) => a.nombre.compareTo(b.nombre));
      return lista;
    });
  }

  /// Fuerza una lectura directa del servidor (ignora la caché local).
  /// Se usa al deslizar hacia abajo en el inventario ("pull to refresh").
  Future<int> recargarDesdeServidor() async {
    final snap = await _productos.where('uid', isEqualTo: _uid).get(const GetOptions(source: Source.server));
    return snap.size;
  }

  Future<bool> existeNombre(String nombre, {String? excluirId}) async {
    final snap = await _productos
        .where('uid', isEqualTo: _uid)
        .where('nombreLower', isEqualTo: nombre.trim().toLowerCase())
        .get();
    return snap.docs.any((d) => d.id != excluirId);
  }

  // -------------------------------------------------------------------- CREAR

  /// App -> Base de datos remota.
  Future<String> crear(Producto p) async {
    final ref = await _productos.add({
      ...p.toMap(),
      'uid': _uid,
      'creadoEn': FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> crearCategoria(String nombre) async {
    await _categorias.add({'uid': _uid, 'nombre': nombre.trim()});
  }

  // --------------------------------------------------------------- ACTUALIZAR

  Future<void> actualizar(Producto p) async {
    await _productos.doc(p.id).update({
      ...p.toMap(),
      'uid': _uid,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------------- ELIMINAR

  Future<void> eliminar(String id) async {
    await _productos.doc(id).delete();
  }

  // ---------------------------------------------- FUNCIONALIDAD PRINCIPAL: VENTA

  /// Registra una venta en una TRANSACCIÓN: lee el stock actual del servidor,
  /// lo descuenta y crea el documento en "ventas". Si dos celulares venden a la
  /// vez, Firestore repite la transacción y el stock nunca queda negativo.
  /// Devuelve el producto con el stock actualizado.
  Future<Producto> vender(String productoId, int cantidad) {
    return _db.runTransaction<Producto>((tx) async {
      final ref = _productos.doc(productoId);
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('El producto ya no existe');
      final p = Producto.fromDoc(doc);
      if (cantidad > p.stock) throw StateError('Solo hay ${p.stock} en stock');

      tx.update(ref, {
        'stock': p.stock - cantidad,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      tx.set(_ventas.doc(), {
        'uid': _uid,
        'productoId': p.id,
        'productoNombre': p.nombre,
        'cantidad': cantidad,
        'precioUnitario': p.precio,
        'total': p.precio * cantidad,
        'fecha': FieldValue.serverTimestamp(),
      });
      return Producto(
        id: p.id,
        uid: p.uid,
        nombre: p.nombre,
        categoria: p.categoria,
        precio: p.precio,
        stock: p.stock - cantidad,
        stockMinimo: p.stockMinimo,
        perecedero: p.perecedero,
      );
    });
  }
}
