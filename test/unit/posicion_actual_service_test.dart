import 'package:dipalza_movil/src/services/posicion_actual_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _actual = PosicionVenta(latitud: -33.45, longitud: -70.66);
const _ultima = PosicionVenta(latitud: -33.40, longitud: -70.60);

void main() {
  test('devuelve la posición actual si llega a tiempo', () async {
    final service = PosicionActualService(
      tienePermiso: () async => true,
      actual: () async => _actual,
      ultimaConocida: () async => _ultima,
    );

    expect(await service.obtener(), _actual);
  });

  test('si el GPS no responde dentro del tope usa la última conocida', () async {
    final service = PosicionActualService(
      tienePermiso: () async => true,
      actual: () => Future.delayed(const Duration(seconds: 10), () => _actual),
      ultimaConocida: () async => _ultima,
      tope: const Duration(milliseconds: 50),
    );

    final inicio = DateTime.now();
    final posicion = await service.obtener();

    expect(posicion, _ultima);
    expect(DateTime.now().difference(inicio), lessThan(const Duration(seconds: 2)));
  });

  test('si no hay permiso devuelve null sin consultar el GPS', () async {
    var consultado = false;
    final service = PosicionActualService(
      tienePermiso: () async => false,
      actual: () async {
        consultado = true;
        return _actual;
      },
      ultimaConocida: () async {
        consultado = true;
        return _ultima;
      },
    );

    expect(await service.obtener(), isNull);
    expect(consultado, isFalse);
  });

  test('si todo falla devuelve null y no lanza excepción', () async {
    final service = PosicionActualService(
      tienePermiso: () async => true,
      actual: () async => throw Exception('GPS apagado'),
      ultimaConocida: () async => throw Exception('sin caché'),
    );

    expect(await service.obtener(), isNull);
  });

  test('si falla la consulta de permiso devuelve null', () async {
    final service = PosicionActualService(
      tienePermiso: () async => throw Exception('plugin no disponible'),
      actual: () async => _actual,
      ultimaConocida: () async => _ultima,
    );

    expect(await service.obtener(), isNull);
  });

  test('conPosicion agrega latitud y longitud solo cuando hay posición', () {
    expect(conPosicion({'idVenta': 1}, _actual),
        {'idVenta': 1, 'latitud': -33.45, 'longitud': -70.66});
    expect(conPosicion({'idVenta': 1}, null), {'idVenta': 1});
  });
}
