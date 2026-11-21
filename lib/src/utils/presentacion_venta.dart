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

/// Hora en formato 24 h, "HH:mm".
String formatoHoraCorta(DateTime hora) =>
    '${hora.hour.toString().padLeft(2, '0')}:'
    '${hora.minute.toString().padLeft(2, '0')}';

/// Lo que va en la cápsula de cada venta en la lista:
/// - Facturada: 'Facturada' (es el único estado que se marca).
/// - Si no, la hora en que quedó terminada, p. ej. '13:30'.
/// - null si no hay hora (venta que nunca se terminó): no se muestra cápsula.
String? textoCapsulaVenta(VentaModel venta) {
  if (venta.estadoVenta == EstadoVenta.CLOSED) return 'Facturada';
  final hora = venta.fechaHoraLista;
  return hora == null ? null : formatoHoraCorta(hora);
}

/// Suma de los totales de [ventas], para el resumen sobre la lista.
double totalDeVentas(List<VentaModel> ventas) =>
    ventas.fold(0.0, (suma, v) => suma + v.total);
