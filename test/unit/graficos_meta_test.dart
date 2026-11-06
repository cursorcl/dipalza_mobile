import 'package:dipalza_movil/src/model/tablero_meta_model.dart';
import 'package:dipalza_movil/src/page/meta/graficos_meta.dart';
import 'package:flutter_test/flutter_test.dart';

TableroMetaModel _tablero({
  double? meta,
  double? avance,
  int dias = 30,
  List<VendidoMesModel>? mensual,
}) =>
    TableroMetaModel(
      periodo: '2026-11',
      calculadoEn: DateTime(2026, 11, 6, 15, 30),
      meta: meta,
      vendido: 0,
      avance: avance,
      cantidadVentas: 0,
      diario: List.generate(
          dias,
          (i) => VendidoDiaModel(
              fecha: DateTime(2026, 11, i + 1), vendido: (i + 1) * 100.0)),
      mensual: mensual ??
          List.generate(
              12,
              (i) => VendidoMesModel(
                  periodo:
                      '${2025 + (i + 11) ~/ 12}-${((i + 10) % 12 + 1).toString().padLeft(2, '0')}',
                  vendido: 1000.0 * (i + 1))),
    );

void main() {
  test('gruposDiarios_unGrupoPorDia', () {
    final grupos = gruposDiarios(_tablero());
    expect(grupos.length, 30);
    expect(grupos[2].x, 3);
    expect(grupos[2].barRods.first.toY, 300);
  });

  test('metaDiariaPromedio_sinMeta_null', () {
    expect(metaDiariaPromedio(_tablero()), isNull);
  });

  test('metaDiariaPromedio_conMeta', () {
    expect(metaDiariaPromedio(_tablero(meta: 30000000, avance: 1)), 1000000);
  });

  test('gruposMensuales_doce', () {
    final grupos = gruposMensuales(_tablero());
    expect(grupos.length, 12);
    expect(grupos.first.barRods.first.toY, 1000);
  });

  test('graficoMensual_metaCero_sinMarca', () {
    final mensual = [
      const VendidoMesModel(periodo: '2026-09', vendido: 10, meta: 0),
      const VendidoMesModel(periodo: '2026-10', vendido: 10),
      const VendidoMesModel(periodo: '2026-11', vendido: 10, meta: 50),
    ];
    final grupos = gruposMensuales(_tablero(mensual: mensual));
    expect(grupos[0].barRods.length, 1);
    expect(grupos[1].barRods.length, 1);
    expect(grupos[2].barRods.length, 2);
    expect(grupos[2].barRods.last.toY, 50);
  });

  test('etiquetaMes_diciembre', () {
    expect(etiquetaMes('2025-12'), 'dic');
    expect(etiquetaMes('2026-01'), 'ene');
  });

  test('maxYDiario_metaMayorQueBarras_incluyeMeta', () {
    // Barra más alta 3000; meta diaria 30.000.000 / 30 = 1.000.000.
    expect(maxYDiario(_tablero(meta: 30000000, avance: 1)),
        closeTo(1000000 * 1.1, 0.001));
  });

  test('maxYDiario_barrasMayoresQueMeta_usaBarras', () {
    // Barra más alta 3000; meta diaria 300 / 30 = 10.
    expect(
        maxYDiario(_tablero(meta: 300, avance: 1)), closeTo(3000 * 1.1, 0.001));
  });

  test('maxYDiario_todoCero_uno', () {
    final t = TableroMetaModel(
      periodo: '2026-11',
      calculadoEn: DateTime(2026, 11, 6),
      meta: null,
      vendido: 0,
      avance: null,
      cantidadVentas: 0,
      diario: [VendidoDiaModel(fecha: DateTime(2026, 11, 1), vendido: 0)],
      mensual: const [],
    );
    expect(maxYDiario(t), 1);
  });
}
