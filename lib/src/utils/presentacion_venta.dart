import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/share/estado.venta.dart';

/// Palabras que no aportan a las iniciales de un nombre o razón social.
const _palabrasIgnoradas = {'Y', 'DE', 'DEL', 'LA', 'LAS', 'LOS', 'EL', '&'};

/// Hasta dos iniciales del nombre del cliente, para el círculo de cada fila:
/// "RAU Y RIQUELME LTDA." → "RR", "JOHNY ROJAS SILVA" → "JR".
String inicialesCliente(String nombre) {
  final palabras = nombre
      .toUpperCase()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty && !_palabrasIgnoradas.contains(p))
      .where((p) => RegExp(r'[A-ZÁÉÍÓÚÑ0-9]').hasMatch(p[0]))
      .toList();
  if (palabras.isEmpty) return '?';
  return palabras.take(2).map((p) => p[0]).join();
}

/// Texto de la etiqueta de estado que se muestra en la lista de ventas.
String etiquetaEstadoVenta(EstadoVenta estado) {
  switch (estado) {
    case EstadoVenta.OPENED:
      return 'Abierta';
    case EstadoVenta.FINISHED:
      return 'Terminada';
    case EstadoVenta.CLOSED:
      return 'Facturada';
  }
}

/// Suma de los totales de [ventas], para el resumen sobre la lista.
double totalDeVentas(List<VentaModel> ventas) =>
    ventas.fold(0.0, (suma, v) => suma + v.total);
