import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/share/estado.venta.dart';
import 'package:dipalza_movil/src/utils/presentacion_venta.dart';
import 'package:flutter_test/flutter_test.dart';

VentaModel _venta(double total) => VentaModel(
      fecha: DateTime(2026, 11, 20),
      rutCliente: '0012345678',
      codigoVendedor: '002',
      codigoRuta: '002',
      codigoCondicionVenta: '001',
      total: total,
    );

void main() {
  group('inicialesCliente', () {
    test('toma la primera letra de las dos primeras palabras', () {
      expect(inicialesCliente('JOHNY ROJAS SILVA'), 'JR');
    });

    test('ignora conectores como Y, DE y &', () {
      expect(inicialesCliente('RAU Y RIQUELME LTDA.'), 'RR');
      expect(inicialesCliente('COMERCIAL V & P  LIMITADA'), 'CV');
      expect(inicialesCliente('SOC.PRESTADORA DE SERVICIOS SPA'), 'SS');
    });

    test('pasa a mayúsculas y respeta la Ñ', () {
      expect(inicialesCliente('ñuñoa market'), 'ÑM');
    });

    test('una sola palabra da una inicial', () {
      expect(inicialesCliente('PROVIPAN'), 'P');
    });

    test('nombre vacío o sin letras da ?', () {
      expect(inicialesCliente(''), '?');
      expect(inicialesCliente('   '), '?');
      expect(inicialesCliente('- .'), '?');
    });
  });

  group('textoCapsulaVenta', () {
    test('facturada también muestra la hora en que quedó terminada', () {
      final v = _venta(1000)
        ..estadoVenta = EstadoVenta.CLOSED
        ..fechaHoraLista = DateTime(2026, 11, 20, 13, 30);
      expect(textoCapsulaVenta(v), '13:30');
    });

    test('facturada sin hora muestra Facturada', () {
      final v = _venta(1000)..estadoVenta = EstadoVenta.CLOSED;
      expect(textoCapsulaVenta(v), 'Facturada');
    });

    test('terminada muestra la hora en que quedó lista, en 24 h', () {
      final v = _venta(1000)
        ..estadoVenta = EstadoVenta.FINISHED
        ..fechaHoraLista = DateTime(2026, 11, 20, 9, 5);
      expect(textoCapsulaVenta(v), '09:05');
      v.fechaHoraLista = DateTime(2026, 11, 20, 17, 45, 59);
      expect(textoCapsulaVenta(v), '17:45');
    });

    test('sin hora (nunca terminada) no muestra cápsula', () {
      expect(textoCapsulaVenta(_venta(1000)), isNull);
    });
  });

  test('fromMap lee fechaHoraLista como hora local y la omite en toMap', () {
    final base = _venta(1000).toMap()
      ..remove('detalles')
      ..['estadoVenta'] = 'FINISHED';
    final conHora = VentaModel.fromMap(
        {...base, 'fechaHoraLista': '2026-11-16T13:30:00.424242'});
    expect(conHora.fechaHoraLista, DateTime(2026, 11, 16, 13, 30, 0, 424, 242));
    expect(conHora.toMap().containsKey('fechaHoraLista'), isFalse);

    final sinHora = VentaModel.fromMap({...base, 'fechaHoraLista': null});
    expect(sinHora.fechaHoraLista, isNull);
  });

  test('totalDeVentas suma los totales', () {
    expect(totalDeVentas([]), 0);
    expect(totalDeVentas([_venta(1000), _venta(2500.5)]), 3500.5);
  });
}
