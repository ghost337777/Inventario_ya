import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Traduce los errores de Firebase a mensajes claros para el usuario.
String mensajeError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'Correo o contraseña incorrectos';
      case 'invalid-email':
        return 'El correo no tiene un formato válido';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo';
      case 'network-request-failed':
        return 'Sin conexión a internet';
      default:
        return 'Error de autenticación (${e.code})';
    }
  }
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'Acceso denegado: no tienes permiso para ver o modificar estos datos';
      case 'unavailable':
        return 'El servidor no está disponible. Revisa tu conexión';
      case 'not-found':
        return 'El registro ya no existe en la base de datos';
      case 'failed-precondition':
      case 'aborted':
        return 'No se pudo completar la operación, intenta de nuevo';
      default:
        return 'Error de base de datos (${e.code})';
    }
  }
  if (e is StateError) return e.message;
  return 'Ocurrió un error inesperado';
}
