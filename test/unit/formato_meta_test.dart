import 'package:dipalza_movil/src/model/tablero_meta_model.dart';
import 'package:dipalza_movil/src/page/meta/formato_meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

TableroMetaModel _tablero({double? meta, double vendido = 0, double? avance}) =>
    TableroMetaModel(
      periodo: '2026-11',
      calculadoEn: DateTime(2026, 11, 6, 15, 30),
      meta: meta,
      vendido: vendido,
      avance: avance,
      cantidadVentas: 0,
      diario: const [],
      mensual: const [],
    );

void main() {
  setUpAll(() => initializeDateFormatting('es_CL'));

  test('formatearAvance', () {
    expect(formatearAvance(61.7), '61,7 %');
    expect(formatearAvance(125), '125,0 %');
    expect(formatearAvance(null), 'Sin meta');
  });

  test('textoFalta', () {
    expect(textoFalta(_tablero(meta: 1000000, vendido: 400000, avance: 40)),
        '\$600.000');
    expect(textoFalta(_tablero(vendido: 10)), isNull);
    expect(textoFalta(_tablero(meta: 100, vendido: 200, avance: 200)), isNull);
  });

  test('metaCumplida', () {
    expect(metaCumplida(_tablero(meta: 100, vendido: 100, avance: 100)), true);
    expect(metaCumplida(_tablero(meta: 100, vendido: 99, avance: 99)), false);
    expect(metaCumplida(_tablero(vendido: 500)), false);
  });

  test('nombreMes', () {
    expect(nombreMes('2026-11'), 'Noviembre 2026');
  });
}
