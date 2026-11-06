import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/provider/meta_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

final _ruta = RequestOptions(path: '/api/metas/mia');

void main() {
  late _MockDio dio;
  late MetaProvider provider;

  setUp(() {
    dio = _MockDio();
    provider = MetaProvider(dio: dio);
  });

  test('metaProvider_ok_mapeaRespuesta', () async {
    when(() => dio.get('/api/metas/mia')).thenAnswer((_) async => Response(
          requestOptions: _ruta,
          statusCode: 200,
          data: {
            'periodo': '2026-11',
            'calculadoEn': '2026-11-06T15:30:00.123-03:00',
            'meta': null,
            'vendido': 10,
            'avance': null,
            'cantidadVentas': 1,
            'diario': [],
            'mensual': [],
          },
        ));
    final t = await provider.obtenerMiMeta();
    expect(t.periodo, '2026-11');
  });

  test('metaProvider_404_lanzaSinVendedor', () async {
    when(() => dio.get('/api/metas/mia')).thenThrow(DioException(
      requestOptions: _ruta,
      response: Response(
        requestOptions: _ruta,
        statusCode: 404,
        data: {'message': 'El usuario no tiene un vendedor asociado.'},
      ),
    ));
    expect(
      provider.obtenerMiMeta(),
      throwsA(isA<MetaSinVendedorException>().having((e) => e.mensaje,
          'mensaje', 'El usuario no tiene un vendedor asociado.')),
    );
  });

  test('metaProvider_500_relanzaDioException', () async {
    when(() => dio.get('/api/metas/mia')).thenThrow(DioException(
      requestOptions: _ruta,
      response: Response(requestOptions: _ruta, statusCode: 500),
    ));
    expect(provider.obtenerMiMeta(), throwsA(isA<DioException>()));
  });
}
