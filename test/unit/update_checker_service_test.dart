import 'package:flutter_test/flutter_test.dart';
import 'package:dipalza_movil/src/services/update_checker_service.dart';

void main() {
  group('esVersionMasNueva', () {
    test('true cuando el patch remoto es mayor', () {
      expect(esVersionMasNueva('2.7.1', '2.7.0'), true);
    });

    test('true cuando el minor remoto es mayor', () {
      expect(esVersionMasNueva('2.8.0', '2.7.9'), true);
    });

    test('compara numéricamente, no como texto (2.10.0 > 2.9.0)', () {
      expect(esVersionMasNueva('2.10.0', '2.9.0'), true);
    });

    test('false cuando son iguales', () {
      expect(esVersionMasNueva('2.7.0', '2.7.0'), false);
    });

    test('false cuando la remota es más antigua', () {
      expect(esVersionMasNueva('2.6.0', '2.7.0'), false);
    });

    test('ignora el sufijo de build number', () {
      expect(esVersionMasNueva('2.7.0+20', '2.7.0+18'), false);
    });

    test('trata segmentos faltantes o no numéricos como 0', () {
      expect(esVersionMasNueva('2.7', '2.7.0'), false);
      expect(esVersionMasNueva('2.x.0', '2.0.0'), false);
    });
  });
}
