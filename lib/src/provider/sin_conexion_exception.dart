import 'dart:async';

import 'package:dio/dio.dart';

/// La operación no llegó al servidor o no obtuvo respuesta (sin señal, server
/// inalcanzable, tiempo agotado). No se sabe si el server la recibió; lo
/// seguro es decirle al vendedor que no se hizo y que reintente.
class SinConexionException implements Exception {
  const SinConexionException();

  /// Devuelve la excepción si [e] es una falla de red; si el server respondió
  /// (aunque sea con error), devuelve null.
  static SinConexionException? desde(Object e) {
    if (e is TimeoutException) return const SinConexionException();
    if (e is DioException && e.response == null) return const SinConexionException();
    return null;
  }

  @override
  String toString() => 'Sin conexión con el servidor';
}
