import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/venta_detalle_model.dart';
import 'package:dipalza_movil/src/provider/sin_conexion_exception.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/services/api_client.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/secure_storage_stub.dart';

class _SinRed implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError);

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureStorage = SecureStorageStub();
  late HttpClientAdapter adaptadorOriginal;

  setUp(() async {
    secureStorage.install();
    SharedPreferences.setMockInitialValues({
      'servidorHost': 'servidor',
      'servidorPuerto': '8080',
      'servidorEsquema': 'http',
      'vendedor': '010',
    });
    await PreferenciasUsuario().initPrefs();
    adaptadorOriginal = ApiClient().dio.httpClientAdapter;
    ApiClient().dio.httpClientAdapter = _SinRed();
  });

  tearDown(() {
    ApiClient().dio.httpClientAdapter = adaptadorOriginal;
    secureStorage.uninstall();
  });

  VentaProvider provider() => VentaProvider.ventaProvider;

  test('sin red, la lista de ventas falla en vez de volver vacía', () async {
    await expectLater(provider().obtenerListaVentas(), throwsA(isA<SinConexionException>()));
  });

  test('sin red, el detalle de una venta falla en vez de volver vacío', () async {
    await expectLater(provider().obtenerListaVentasDetalle(7), throwsA(isA<SinConexionException>()));
  });

  test('sin red, grabar un producto avisa sin conexión', () async {
    final detalle = VentaDetalleModel(
        id: -1, ventaId: 7, idProducto: 'P1', nombreProducto: 'Queso',
        cantidad: 1, precioUnitario: 1000, porcentajeDescuento: 0,
        porcentajeIva: 19, porcentajeIla: 0, totalDescuento: 0, totalIva: 190,
        totalIla: 0, totalLinea: 1000, unidad: 'un', piezas: 0, piezasDetalle: []);

    await expectLater(provider().saveItemVenta(detalle), throwsA(isA<SinConexionException>()));
  });
}
