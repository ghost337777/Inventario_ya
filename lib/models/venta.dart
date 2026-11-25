import 'package:cloud_firestore/cloud_firestore.dart';

/// Venta registrada (colección "ventas" en Firestore).
class Venta {
  final String id;
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final int precioUnitario;
  final int total;
  final DateTime fecha;

  const Venta({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.fecha,
  });

  factory Venta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Venta(
      id: doc.id,
      productoId: d['productoId'] as String? ?? '',
      productoNombre: d['productoNombre'] as String? ?? '',
      cantidad: (d['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (d['precioUnitario'] as num?)?.toInt() ?? 0,
      total: (d['total'] as num?)?.toInt() ?? 0,
      // Mientras la escritura está pendiente, la fecha del servidor aún es null.
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get esDeHoy {
    final hoy = DateTime.now();
    return fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
  }
}
