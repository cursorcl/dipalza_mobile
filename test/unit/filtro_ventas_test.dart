import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/utils/filtro_ventas.dart';
import 'package:flutter_test/flutter_test.dart';

VentaModel _venta(int id, String nombre, String rut) => VentaModel(
      id: id,
      fecha: DateTime(2026, 11, 20),
      rutCliente: rut,
      nombreCliente: nombre,
      codigoVendedor: '01',
      codigoRuta: '01',
      codigoCondicionVenta: '01',
    );

void main() {
  final ventas = [
    _venta(1, 'Almacén Doña Rosa', '0012345678'),
    _venta(2, 'Supermercado El Sol', '0076543219'),
    _venta(3, 'Minimarket Peñalolén', '011111111K'),
  ];

  List<int> ids(List<VentaModel> l) => l.map((v) => v.id).toList();

  test('texto vacío o solo espacios devuelve la lista completa', () {
    expect(ids(filtrarVentas(ventas, '')), [1, 2, 3]);
    expect(ids(filtrarVentas(ventas, '   ')), [1, 2, 3]);
  });

  test('busca por parte del nombre sin importar mayúsculas', () {
    expect(ids(filtrarVentas(ventas, 'sol')), [2]);
    expect(ids(filtrarVentas(ventas, 'MARKET')), [3]);
  });

  test('busca por nombre ignorando tildes y la ñ', () {
    expect(ids(filtrarVentas(ventas, 'almacen dona')), [1]);
    expect(ids(filtrarVentas(ventas, 'penalolen')), [3]);
    expect(ids(filtrarVentas(ventas, 'Peñalolén')), [3]);
  });

  test('busca por rut con o sin puntos y guion', () {
    expect(ids(filtrarVentas(ventas, '1.234.567-8')), [1]);
    expect(ids(filtrarVentas(ventas, '12345678')), [1]);
    expect(ids(filtrarVentas(ventas, '7654')), [2]);
  });

  test('busca por rut con dígito verificador K en minúscula', () {
    expect(ids(filtrarVentas(ventas, '11.111.111-k')), [3]);
  });

  test('mantiene el orden original de la lista', () {
    expect(ids(filtrarVentas(ventas, 'a')), [1, 2, 3]);
  });

  test('sin coincidencias devuelve lista vacía', () {
    expect(filtrarVentas(ventas, 'ferretería'), isEmpty);
  });
}
