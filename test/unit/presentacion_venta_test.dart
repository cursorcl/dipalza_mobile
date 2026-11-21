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

  test('etiquetaEstadoVenta', () {
    expect(etiquetaEstadoVenta(EstadoVenta.OPENED), 'Abierta');
    expect(etiquetaEstadoVenta(EstadoVenta.FINISHED), 'Terminada');
    expect(etiquetaEstadoVenta(EstadoVenta.CLOSED), 'Facturada');
  });

  test('totalDeVentas suma los totales', () {
    expect(totalDeVentas([]), 0);
    expect(totalDeVentas([_venta(1000), _venta(2500.5)]), 3500.5);
  });
}
