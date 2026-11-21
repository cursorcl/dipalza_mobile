import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/utils/filtro_clientes.dart';
import 'package:flutter_test/flutter_test.dart';

ClientesModel _cliente({String rut = '010951201K', String codigo = '', String razon = 'CLARISA TAPIA VARAS'}) =>
    ClientesModel(
        rut: rut, codigo: codigo, razon: razon, direccion: '', telefono: '', ciudad: '', giro: '', ruta: '');

void main() {
  group('coincideCliente', () {
    test('busca por nombre sin distinguir mayúsculas', () {
      expect(coincideCliente(_cliente(), 'tapia'), isTrue);
    });

    test('busca por código', () {
      expect(coincideCliente(_cliente(codigo: '001'), '001'), isTrue);
    });

    test('busca por RUT con puntos y guion', () {
      expect(coincideCliente(_cliente(), '10.951.201-K'), isTrue);
    });

    test('busca por RUT sin formato, con dígito verificador en minúscula', () {
      expect(coincideCliente(_cliente(), '10951201k'), isTrue);
    });

    test('busca por parte del RUT', () {
      expect(coincideCliente(_cliente(), '1095120'), isTrue);
    });

    test('el RUT guardado con ceros a la izquierda calza igual', () {
      expect(coincideCliente(_cliente(rut: '0054251009'), '5.425.100'), isTrue);
    });

    test('un texto que no está en nombre, código ni RUT no calza', () {
      expect(coincideCliente(_cliente(), '99999'), isFalse);
      expect(coincideCliente(_cliente(), 'perez'), isFalse);
    });

    test('un nombre no se compara contra el RUT', () {
      // "K" sola está en el RUT 010951201K, pero el texto es un nombre.
      expect(coincideCliente(_cliente(razon: 'ANA SOTO'), 'k'), isFalse);
    });

    test('texto vacío no calza', () {
      expect(coincideCliente(_cliente(), '  '), isFalse);
    });
  });
}
