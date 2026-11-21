import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Posición del celular al grabar o finalizar una venta.
class PosicionVenta {
  final double latitud;
  final double longitud;

  /// Cuándo la tomó el GPS; solo se conoce para la última posición conocida.
  final DateTime? tomadaEn;

  const PosicionVenta({required this.latitud, required this.longitud, this.tomadaEn});

  @override
  bool operator ==(Object other) =>
      other is PosicionVenta &&
      other.latitud == latitud &&
      other.longitud == longitud;

  @override
  int get hashCode => Object.hash(latitud, longitud);
}

/// Obtiene la posición actual para registrarla en la venta, sin bloquearla:
/// todo el proceso dura a lo más [tope]. Se espera el GPS hasta el 60 % del
/// tope; si no responde se usa la última posición conocida, siempre que tenga a
/// lo más [antiguedadMaxima] (una más vieja dibujaría la venta en otro lugar).
/// Si no hay ninguna devuelve `null`. Nunca lanza excepción.
class PosicionActualService {
  static const antiguedadMaxima = Duration(minutes: 5);

  final Future<bool> Function() _tienePermiso;
  final Future<PosicionVenta?> Function() _actual;
  final Future<PosicionVenta?> Function() _ultimaConocida;
  final DateTime Function() _ahora;
  final Duration _tope;

  PosicionActualService({
    Future<bool> Function()? tienePermiso,
    Future<PosicionVenta?> Function()? actual,
    Future<PosicionVenta?> Function()? ultimaConocida,
    DateTime Function()? ahora,
    Duration tope = const Duration(seconds: 5),
  })  : _tienePermiso = tienePermiso ?? _permisoGeolocator,
        _actual = actual ?? _actualGeolocator,
        _ultimaConocida = ultimaConocida ?? _ultimaGeolocator,
        _ahora = ahora ?? DateTime.now,
        _tope = tope;

  Future<PosicionVenta?> obtener() async {
    try {
      return await _obtener().timeout(_tope, onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  Future<PosicionVenta?> _obtener() async {
    if (!await _tienePermiso()) return null;
    try {
      final posicion = await _actual().timeout(_tope * 0.6);
      if (posicion != null) return posicion;
    } catch (_) {
      // Vence el tiempo o el GPS falla: se intenta con la última conocida.
    }
    final ultima = await _ultimaConocida();
    if (ultima == null) return null;
    final tomadaEn = ultima.tomadaEn;
    if (tomadaEn != null && _ahora().difference(tomadaEn) > antiguedadMaxima) {
      return null;
    }
    return ultima;
  }

  static Future<bool> _permisoGeolocator() async {
    final permiso = await Geolocator.checkPermission();
    return permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse;
  }

  static Future<PosicionVenta?> _actualGeolocator() async {
    final p = await Geolocator.getCurrentPosition();
    return PosicionVenta(latitud: p.latitude, longitud: p.longitude);
  }

  static Future<PosicionVenta?> _ultimaGeolocator() async {
    final p = await Geolocator.getLastKnownPosition();
    if (p == null) return null;
    return PosicionVenta(latitud: p.latitude, longitud: p.longitude, tomadaEn: p.timestamp);
  }
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
