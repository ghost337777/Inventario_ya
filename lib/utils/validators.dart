/// Validaciones reutilizables para los formularios.
class Validators {
  static String? nombre(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El nombre es obligatorio';
    if (t.length < 3) return 'Debe tener al menos 3 caracteres';
    if (t.length > 40) return 'Máximo 40 caracteres';
    return null;
  }

  static String? precio(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Obligatorio';
    final n = int.tryParse(t);
    if (n == null) return 'Ingresa solo números';
    if (n <= 0) return 'Debe ser mayor a 0';
    if (n > 10000000) return 'El precio es demasiado alto';
    return null;
  }

  static String? stock(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Obligatorio';
    final n = int.tryParse(t);
    if (n == null) return 'Ingresa solo números enteros';
    if (n < 0) return 'No puede ser negativa';
    if (n > 100000) return 'Cantidad demasiado alta';
    return null;
  }

  /// Cantidad a vender: entre 1 y el stock disponible.
  static String? cantidadVenta(String? v, int disponible) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa la cantidad';
    final n = int.tryParse(t);
    if (n == null || n <= 0) return 'Debe ser un número mayor a 0';
    if (n > disponible) return 'Solo hay $disponible en stock';
    return null;
  }
}
