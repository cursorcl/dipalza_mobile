import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dipalza_movil/src/page/login/auth_gate.dart';
import 'package:dipalza_movil/src/services/api_client.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';

class MockApiClient extends Mock implements ApiClient {}

/// El canal de `flutter_secure_storage` no tiene implementación bajo
/// `flutter test` (no hay plataforma nativa real). `PreferenciasUsuario` es
/// un singleton real (por convención del repo no se mockea directamente), así
/// que se simula el canal en memoria para que sus getters/setters de
/// `refreshToken`/`access_token` y `borrarCredenciales()` funcionen.
class _SecureStorageChannelStub {
  static const _channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> _values = {};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case 'read':
        return _values[call.arguments['key']];
      case 'write':
        _values[call.arguments['key']] = call.arguments['value'];
        return null;
      case 'readAll':
        return _values;
      case 'delete':
        _values.remove(call.arguments['key']);
        return null;
      case 'deleteAll':
        _values.clear();
        return null;
      default:
        return null;
    }
  }
}

/// Arma un JWT con firma falsa pero payload real, suficiente para que
/// `JwtDecoder.isExpired` (que solo lee el claim `exp`, no valida la firma)
/// lo trate como un token no expirado.
String _crearJwtConExpiracion(DateTime expiracion) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
  final payload = base64Url.encode(
      utf8.encode('{"exp":${expiracion.millisecondsSinceEpoch ~/ 1000}}'));
  final signature = base64Url.encode(utf8.encode('firma'));
  return '$header.$payload.$signature';
}

void main() {
  final secureStorage = _SecureStorageChannelStub();
  late MockApiClient mockApiClient;
  late PreferenciasUsuario prefs;

  setUp(() {
    secureStorage.install();
    mockApiClient = MockApiClient();
    prefs = PreferenciasUsuario();
  });

  tearDown(() async {
    await prefs.borrarCredenciales();
    secureStorage.uninstall();
  });

  Widget crearWidgetDePrueba() {
    return MaterialApp(
      home: AuthGate(apiClient: mockApiClient),
      routes: {
        AppRoutes.login: (_) =>
            const Scaffold(body: Text('LoginPage (stub)')),
        AppRoutes.home: (_) => const Scaffold(body: Text('Home (stub)')),
      },
    );
  }

  testWidgets(
      'con mustChangePassword=true en la renovación silenciosa, '
      'navega a login (no a Home) y borra las credenciales guardadas',
      (tester) async {
    final tokenValido =
        _crearJwtConExpiracion(DateTime.now().add(const Duration(hours: 1)));
    prefs.refreshToken = tokenValido;

    when(() => mockApiClient.renovarToken()).thenAnswer(
      (_) async => const RenovarTokenResultado(
        exitoso: true,
        mustChangePassword: true,
      ),
    );

    await tester.pumpWidget(crearWidgetDePrueba());
    await tester.pump(const Duration(seconds: 2)); // espera fija del splash
    await tester.pumpAndSettle();

    expect(find.text('LoginPage (stub)'), findsOneWidget);
    expect(find.text('Home (stub)'), findsNothing);
    expect(prefs.refreshToken, isEmpty);

    verify(() => mockApiClient.renovarToken()).called(1);
  });
}
