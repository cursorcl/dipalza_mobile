import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Posición del celular al grabar o finalizar una venta.
class PosicionVenta {
  final double latitud;
  final double longitud;

  const PosicionVenta({required this.latitud, required this.longitud});

  @override
  bool operator ==(Object other) =>
      other is PosicionVenta &&
      other.latitud == latitud &&
      other.longitud == longitud;

  @override
  int get hashCode => Object.hash(latitud, longitud);
}

/// Obtiene la posición actual para registrarla en la venta, sin bloquearla:
/// espera a lo más [tope] por el GPS, luego usa la última posición conocida, y
/// si tampoco hay devuelve `null`. Nunca lanza excepción.
class PosicionActualService {
  final Future<bool> Function() _tienePermiso;
  final Future<PosicionVenta?> Function() _actual;
  final Future<PosicionVenta?> Function() _ultimaConocida;
  final Duration _tope;

  PosicionActualService({
    Future<bool> Function()? tienePermiso,
    Future<PosicionVenta?> Function()? actual,
    Future<PosicionVenta?> Function()? ultimaConocida,
    Duration tope = const Duration(seconds: 5),
  })  : _tienePermiso = tienePermiso ?? _permisoGeolocator,
        _actual = actual ?? _actualGeolocator,
        _ultimaConocida = ultimaConocida ?? _ultimaGeolocator,
        _tope = tope;

  Future<PosicionVenta?> obtener() async {
    try {
      if (!await _tienePermiso()) return null;
    } catch (_) {
      return null;
    }
    try {
      final posicion = await _actual().timeout(_tope);
      if (posicion != null) return posicion;
    } catch (_) {
      // Vence el tope o el GPS falla: se intenta con la última conocida.
    }
    try {
      return await _ultimaConocida();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _permisoGeolocator() async {
    final permiso = await Geolocator.checkPermission();
    return permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse;
  }

  static Future<PosicionVenta?> _actualGeolocator() async =>
      _desde(await Geolocator.getCurrentPosition());

  static Future<PosicionVenta?> _ultimaGeolocator() async {
    final posicion = await Geolocator.getLastKnownPosition();
    return posicion == null ? null : _desde(posicion);
  }

  static PosicionVenta _desde(Position p) =>
      PosicionVenta(latitud: p.latitude, longitud: p.longitude);
}

/// Agrega `latitud`/`longitud` al cuerpo del POST solo si hay posición: el
/// server las trata como opcionales.
Map<String, dynamic> conPosicion(
    Map<String, dynamic> datos, PosicionVenta? posicion) {
  if (posicion == null) return datos;
  return {
    ...datos,
    'latitud': posicion.latitud,
    'longitud': posicion.longitud,
  };
}
