import 'package:dipalza_movil/src/model/venta_model.dart';

const _conTilde = 'ÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ';
const _sinTilde = 'AAAAEEEEIIIIOOOOUUUUN';

/// Pasa a mayúsculas y quita tildes y la Ñ, para comparar nombres sin
/// depender de cómo los escribió el vendedor.
String _normalizarTexto(String texto) {
  final mayus = texto.toUpperCase();
  final buffer = StringBuffer();
  for (final letra in mayus.split('')) {
    final i = _conTilde.indexOf(letra);
    buffer.write(i >= 0 ? _sinTilde[i] : letra);
  }
  return buffer.toString();
}

/// Deja solo dígitos y K, sin ceros a la izquierda: '0012345678',
/// '1.234.567-8' y '12345678' quedan iguales.
String _normalizarRut(String rut) {
  return rut
      .toUpperCase()
      .replaceAll(RegExp(r'[^0-9K]'), '')
      .replaceFirst(RegExp(r'^0+'), '');
}

/// Filtra las ventas cuyo nombre de cliente o rut contienen [texto].
/// Respeta el orden de [ventas]. Con texto vacío devuelve todas.
List<VentaModel> filtrarVentas(List<VentaModel> ventas, String texto) {
  final consulta = texto.trim();
  if (consulta.isEmpty) return ventas;

  final nombreBuscado = _normalizarTexto(consulta);
  // El rut solo se compara si la búsqueda trae algún dígito; si no, una
  // búsqueda como "k" coincidiría con cualquier rut terminado en K.
  final rutBuscado =
      consulta.contains(RegExp(r'[0-9]')) ? _normalizarRut(consulta) : '';

  return ventas.where((venta) {
    if (_normalizarTexto(venta.nombreCliente).contains(nombreBuscado)) {
      return true;
    }
    return rutBuscado.isNotEmpty &&
        _normalizarRut(venta.rutCliente).contains(rutBuscado);
  }).toList();
}
