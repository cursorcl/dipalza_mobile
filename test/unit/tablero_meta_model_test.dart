import 'package:dipalza_movil/src/model/tablero_meta_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({dynamic meta = 35751000.0, dynamic avance}) => {
      'periodo': '2026-11',
      'calculadoEn': '2026-11-06T15:30:00.123-03:00',
      'meta': meta,
      'vendido': 150000,
      'avance': avance,
      'cantidadVentas': 4,
      'diario': [
        {'fecha': '2026-11-03', 'vendido': 100},
        {'fecha': '2026-11-04', 'vendido': 50.5},
      ],
      'mensual': [
        {'periodo': '2025-12', 'vendido': 0, 'meta': null},
        {'periodo': '2026-11', 'vendido': 150000.0, 'meta': 35751000},
      ],
    };

void main() {
  test('tableroMeta_fromJson_numerosIntYDoubleYNull', () {
    final t = TableroMetaModel.fromJson(_json());
    expect(t.periodo, '2026-11');
    expect(t.vendido, 150000.0);
    expect(t.meta, 35751000.0);
    expect(t.avance, isNull);
    expect(t.cantidadVentas, 4);
    expect(t.diario.first.fecha, DateTime(2026, 11, 3));
    expect(t.diario.last.vendido, 50.5);
    expect(t.mensual.first.meta, isNull);
    expect(t.mensual.last.meta, 35751000.0);
    expect(t.calculadoEn.toUtc(), DateTime.utc(2026, 11, 6, 18, 30, 0, 123));
  });

  test('tableroMeta_tieneMeta', () {
    expect(TableroMetaModel.fromJson(_json(meta: null)).tieneMeta, false);
    expect(TableroMetaModel.fromJson(_json(meta: 0)).tieneMeta, false);
    expect(TableroMetaModel.fromJson(_json(meta: 100)).tieneMeta, false);
    expect(TableroMetaModel.fromJson(_json(meta: 100, avance: 61.7)).tieneMeta,
        true);
  });
}
