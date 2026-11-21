import 'dart:async';

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

  test('descarta la última conocida si tiene más de 5 minutos', () async {
    final ahora = DateTime(2026, 11, 21, 10, 0);
    final service = PosicionActualService(
      tienePermiso: () async => true,
      actual: () async => throw Exception('GPS apagado'),
      ultimaConocida: () async => PosicionVenta(
          latitud: -33.40, longitud: -70.60, tomadaEn: ahora.subtract(const Duration(minutes: 6))),
      ahora: () => ahora,
    );

    expect(await service.obtener(), isNull);
  });

  test('acepta la última conocida reciente', () async {
    final ahora = DateTime(2026, 11, 21, 10, 0);
    final reciente = PosicionVenta(
        latitud: -33.40, longitud: -70.60, tomadaEn: ahora.subtract(const Duration(minutes: 2)));
    final service = PosicionActualService(
      tienePermiso: () async => true,
      actual: () async => throw Exception('GPS apagado'),
      ultimaConocida: () async => reciente,
      ahora: () => ahora,
    );

    expect(await service.obtener(), reciente);
  });

  test('si la última conocida se cuelga, obtener termina igual con null', () async {
    final service = PosicionActualService(
      tienePermiso: () async => true,
      actual: () => Completer<PosicionVenta?>().future,
      ultimaConocida: () => Completer<PosicionVenta?>().future,
      tope: const Duration(milliseconds: 50),
    );

    final inicio = DateTime.now();
    expect(await service.obtener(), isNull);
    expect(DateTime.now().difference(inicio), lessThan(const Duration(seconds: 2)));
  });

  test('si la consulta de permiso se cuelga, obtener termina igual con null', () async {
    final service = PosicionActualService(
      tienePermiso: () => Completer<bool>().future,
      actual: () async => _actual,
      ultimaConocida: () async => _ultima,
      tope: const Duration(milliseconds: 50),
    );

    expect(await service.obtener(), isNull);
  });
}
