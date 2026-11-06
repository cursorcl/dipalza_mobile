import 'package:dio/dio.dart';

/// El servidor rechazó la operación sobre la venta (HTTP 409) y explicó el motivo,
/// por ejemplo un cliente inactivo o una venta ya facturada. [mensaje] viene listo
/// para mostrárselo al vendedor.
class VentaRechazadaException implements Exception {
  final String mensaje;

  const VentaRechazadaException(this.mensaje);

  /// Devuelve la excepción si [e] es un 409 con `{"message": ...}`; si no, null.
  static VentaRechazadaException? desde(DioException e) {
    if (e.response?.statusCode != 409) return null;
    final data = e.response?.data;
    if (data is Map) {
      final mensaje = data['message'];
      if (mensaje is String && mensaje.trim().isNotEmpty) {
        return VentaRechazadaException(mensaje);
      }
    }
    return null;
  }

  @override
  String toString() => mensaje;
}
