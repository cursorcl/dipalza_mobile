import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/services/api_client.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/secure_storage_stub.dart';

/// Adaptador HTTP falso: cada request se resuelve con [responder].
class _Adaptador implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) responder;
  _Adaptador(this.responder);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      responder(options);

  @override
  void close({bool force = false}) {}
}

Future<ResponseBody> _sinRed(RequestOptions o) async =>
    throw DioException(requestOptions: o, type: DioExceptionType.connectionError);

Future<ResponseBody> _respuesta401(RequestOptions o) async =>
    ResponseBody.fromString('{}', 401, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureStorage = SecureStorageStub();
  late PreferenciasUsuario prefs;
  late ApiClient api;

  setUp(() async {
    secureStorage.install();
    SharedPreferences.setMockInitialValues({
      'servidorHost': 'servidor',
      'servidorPuerto': '8080',
      'servidorEsquema': 'http',
    });
    prefs = PreferenciasUsuario();
    await prefs.initPrefs();
    prefs.access_token = 'access';
    prefs.refreshToken = 'refresh';
    api = ApiClient();
    api.resetEstadoRefresh();
  });

  tearDown(() async {
    await prefs.borrarCredenciales();
    secureStorage.uninstall();
  });

  group('renovarToken', () {
    test('sin red: falla marcada como sin conexión y no toca las credenciales', () async {
      api.dioRefresh.httpClientAdapter = _Adaptador(_sinRed);

      final resultado = await api.renovarToken();

      expect(resultado.exitoso, isFalse);
      expect(resultado.sinConexion, isTrue);
      expect(prefs.refreshToken, 'refresh');
    });

    test('el server rechaza la sesión: falla sin marca de sin conexión', () async {
      api.dioRefresh.httpClientAdapter = _Adaptador(_respuesta401);

      final resultado = await api.renovarToken();

      expect(resultado.exitoso, isFalse);
      expect(resultado.sinConexion, isFalse);
    });
  });

  group('durante el uso (token vencido)', () {
    test('si la renovación falla por red, no se avisa sesión expirada', () async {
      var expiradas = 0;
      final sub = api.onSessionExpired.listen((_) => expiradas++);
      api.dio.httpClientAdapter = _Adaptador(_respuesta401);
      api.dioRefresh.httpClientAdapter = _Adaptador(_sinRed);

      await expectLater(api.dio.get('/api/ventas'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(expiradas, 0);
      await sub.cancel();
    });

    test('si el server rechaza la renovación, sí se avisa sesión expirada', () async {
      var expiradas = 0;
      final sub = api.onSessionExpired.listen((_) => expiradas++);
      api.dio.httpClientAdapter = _Adaptador(_respuesta401);
      api.dioRefresh.httpClientAdapter = _Adaptador(_respuesta401);

      await expectLater(api.dio.get('/api/ventas'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);

      expect(expiradas, 1);
      await sub.cancel();
    });
  });
}
