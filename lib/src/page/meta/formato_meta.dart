import 'package:intl/intl.dart';

import '../../model/tablero_meta_model.dart';
import '../../utils/utils.dart';

/// Monto con formato "$12.345.678". `getValorModena` deja un espacio al final
/// (símbolo de moneda vacío), por eso se recorta.
String formatearMonto(double valor) => getValorModena(valor, 0).trim();

/// Porcentaje de avance con 1 decimal ("61,7 %"), o "Sin meta" si no hay avance.
String formatearAvance(double? avance) {
  if (avance == null) return 'Sin meta';
  return '${NumberFormat('0.0', 'es_CL').format(avance)} %';
}

/// Monto que falta para la meta, o null si no hay meta o ya se cumplió.
String? textoFalta(TableroMetaModel t) {
  if (!t.tieneMeta) return null;
  final falta = t.meta! - t.vendido;
  if (falta <= 0) return null;
  return formatearMonto(falta);
}

bool metaCumplida(TableroMetaModel t) {
  return t.tieneMeta && t.vendido >= t.meta!;
}

/// "2026-11" -> "Noviembre 2026". Requiere `initializeDateFormatting('es_CL')`.
String nombreMes(String periodo) {
  final partes = periodo.split('-');
  final fecha = DateTime(int.parse(partes[0]), int.parse(partes[1]));
  final texto = DateFormat('MMMM y', 'es_CL').format(fecha);
  return texto[0].toUpperCase() + texto.substring(1);
}
