import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/categoria.dart';

/// Autenticación con Firebase Authentication (correo y contraseña).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Emite el usuario actual cada vez que inicia o cierra sesión.
  Stream<User?> get cambiosDeSesion => _auth.authStateChanges();

  User? get usuario => _auth.currentUser;

  Future<void> iniciarSesion(String correo, String clave) async {
    await _auth.signInWithEmailAndPassword(email: correo.trim(), password: clave);
  }

  /// Crea la cuenta, el perfil en "usuarios/{uid}" y las categorías iniciales.
  Future<void> crearCuenta({required String correo, required String clave, required String tienda}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: correo.trim(), password: clave);
    final uid = cred.user!.uid;

    final batch = _db.batch();
    batch.set(_db.collection('usuarios').doc(uid), {
      'correo': correo.trim(),
      'tienda': tienda.trim(),
      'creadoEn': FieldValue.serverTimestamp(),
    });
    for (final nombre in Categoria.porDefecto) {
      batch.set(_db.collection('categorias').doc(), {'uid': uid, 'nombre': nombre});
    }
    await batch.commit();
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Nombre de la tienda guardado en el perfil del usuario.
  Stream<String> tiendaStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value('');
    return _db.collection('usuarios').doc(uid).snapshots().map((d) => d.data()?['tienda'] as String? ?? '');
  }
}
