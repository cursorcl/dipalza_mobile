import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/tablero_meta_model.dart';
import 'package:dipalza_movil/src/page/meta/graficos_meta.dart';
import 'package:dipalza_movil/src/page/meta/meta.page.dart';
import 'package:dipalza_movil/src/provider/meta_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockMetaProvider extends Mock implements MetaProvider {}

TableroMetaModel _tablero({double? meta, double? avance, double vendido = 0}) =>
    TableroMetaModel(
      periodo: '2026-11',
      calculadoEn: DateTime(2026, 11, 6, 15, 30),
      meta: meta,
      vendido: vendido,
      avance: avance,
      cantidadVentas: 4,
      diario: const [],
      mensual: const [],
    );

void main() {
  late _MockMetaProvider provider;

  setUpAll(() => initializeDateFormatting('es_CL'));
  setUp(() => provider = _MockMetaProvider());

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: MetaPage(provider: provider)));
    await tester.pumpAndSettle();
  }

  testWidgets('metaPage_conMeta_muestraCifrasDespuesDeGraficos',
      (tester) async {
    when(() => provider.obtenerMiMeta()).thenAnswer(
        (_) async => _tablero(meta: 2000000, vendido: 1234567, avance: 61.7));
    await montar(tester);
    expect(find.text('\$1.234.567'), findsOneWidget);
    expect(find.text('\$2.000.000'), findsOneWidget);
    expect(find.text('61,7 %'), findsWidgets);
    expect(find.text('\$765.433'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(TabBar)).dy,
        lessThan(tester.getTopLeft(find.text('\$1.234.567')).dy));
    expect(find.text('Noviembre 2026'), findsOneWidget);
    expect(find.text('4 ventas cerradas'), findsOneWidget);
    expect(find.text('Actualizado a las 15:30'), findsOneWidget);
  });

  testWidgets('metaPage_sinMeta_muestraTextoYGraficos', (tester) async {
    when(() => provider.obtenerMiMeta())
        .thenAnswer((_) async => _tablero(vendido: 1000));
    await montar(tester);
    expect(find.text('Sin meta asignada este mes'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(TabBar)).dy,
        lessThan(tester.getTopLeft(find.text('\$1.000')).dy));
    expect(find.text('Ventas del mes'), findsOneWidget);
    expect(find.text('Últimos 12 meses'), findsOneWidget);
    expect(find.byType(GraficoDiarioMeta), findsOneWidget);
  });

  testWidgets('metaPage_metaSuperada_muestraCumplida', (tester) async {
    when(() => provider.obtenerMiMeta()).thenAnswer(
        (_) async => _tablero(meta: 1000, vendido: 1250, avance: 125));
    await montar(tester);
    expect(find.text('125,0 %'), findsWidgets);
    expect(find.text('¡Meta cumplida!'), findsOneWidget);
    expect(find.text('Falta'), findsNothing);
  });

  testWidgets('metaPage_sinVendedor_muestraMensaje', (tester) async {
    when(() => provider.obtenerMiMeta()).thenThrow(
        const MetaSinVendedorException(
            'El usuario no tiene un vendedor asociado.'));
    await montar(tester);
    expect(
        find.text('El usuario no tiene un vendedor asociado.'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('metaPage_error_reintenta', (tester) async {
    when(() => provider.obtenerMiMeta()).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/metas/mia')));
    await montar(tester);
    expect(find.text('No se pudo cargar tu meta.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    verify(() => provider.obtenerMiMeta()).called(2);
  });

  testWidgets('metaPage_tituloEsElMesYSinNota', (tester) async {
    when(() => provider.obtenerMiMeta()).thenAnswer(
        (_) async => _tablero(meta: 1000, vendido: 500, avance: 50));
    await montar(tester);
    expect(
        find.descendant(
            of: find.byType(AppBar), matching: find.text('Noviembre 2026')),
        findsOneWidget);
    expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Meta')),
        findsNothing);
    expect(find.textContaining('Se cuentan las ventas transferidas'),
        findsNothing);
  });

  testWidgets('metaPage_graficosEnTabs', (tester) async {
    when(() => provider.obtenerMiMeta()).thenAnswer(
        (_) async => _tablero(meta: 1000, vendido: 500, avance: 50));
    await montar(tester);
    expect(find.text('Ventas del mes'), findsOneWidget);
    expect(find.text('Últimos 12 meses'), findsOneWidget);
    expect(find.byType(GraficoDiarioMeta), findsOneWidget);
    await tester.tap(find.text('Últimos 12 meses'));
    await tester.pumpAndSettle();
    expect(find.byType(GraficoMensualMeta), findsOneWidget);
  });

  testWidgets('metaPage_graficosConBorde', (tester) async {
    when(() => provider.obtenerMiMeta()).thenAnswer(
        (_) async => _tablero(meta: 1000, vendido: 500, avance: 50));
    await montar(tester);
    final contenedor =
        tester.widget<Container>(find.byKey(const Key('contenedor-grafico')));
    expect((contenedor.decoration as BoxDecoration).border, isNotNull);
  });

  testWidgets('metaPage_pullToRefresh_conservaDatosMientrasRecarga',
      (tester) async {
    var llamadas = 0;
    final completer = Completer<TableroMetaModel>();
    when(() => provider.obtenerMiMeta()).thenAnswer((_) {
      llamadas++;
      if (llamadas == 1) {
        return Future.value(
            _tablero(meta: 2000000, vendido: 1234567, avance: 61.7));
      }
      return completer.future;
    });
    await montar(tester);
    expect(find.text('\$1.234.567'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 1500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(llamadas, 2);
    expect(find.text('\$1.234.567'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    completer.complete(_tablero(meta: 2000000, vendido: 1500000, avance: 75));
    await tester.pumpAndSettle();
    expect(find.text('\$1.500.000'), findsOneWidget);
  });
}
