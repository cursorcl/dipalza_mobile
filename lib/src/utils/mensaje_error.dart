import 'package:dipalza_movil/src/provider/sin_conexion_exception.dart';
import 'package:dipalza_movil/src/provider/venta_rechazada_exception.dart';

/// Mensaje para el vendedor cuando falla [accion] (p. ej. "grabar el
/// producto"): sin detalles técnicos ni stack traces.
String mensajeParaVendedor(Object e, {required String accion}) {
  if (e is VentaRechazadaException) return e.mensaje;
  if (e is SinConexionException || SinConexionException.desde(e) != null) {
    return 'Sin conexión: no se pudo $accion. Revisa la señal e intenta nuevamente.';
  }
  return 'No se pudo $accion. Intenta nuevamente.';
}
