import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula en memoria el canal de `flutter_secure_storage`, que no tiene
/// implementación bajo `flutter test`. Permite usar el singleton real
/// `PreferenciasUsuario` (tokens, `borrarCredenciales()`) en las pruebas.
class SecureStorageStub {
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
