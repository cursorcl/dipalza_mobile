import 'package:dipalza_movil/src/model/login_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parsea mustChangePassword en true', () {
    final model = LoginResponseModel.fromJson({
      'accessToken': 'a',
      'refreshToken': 'r',
      'expiresInSeconds': 600,
      'mustChangePassword': true,
      'vendedor': {'codigo': '001', 'tipo': '0', 'rut': '11111111-1', 'nombre': 'Juan Perez'},
    });

    expect(model.mustChangePassword, isTrue);
  });

  test('fromJson por defecto deja mustChangePassword en false si no viene', () {
    final model = LoginResponseModel.fromJson({
      'accessToken': 'a',
      'refreshToken': 'r',
      'expiresInSeconds': 600,
      'vendedor': {'codigo': '001', 'tipo': '0', 'rut': '11111111-1', 'nombre': 'Juan Perez'},
    });

    expect(model.mustChangePassword, isFalse);
  });
}
