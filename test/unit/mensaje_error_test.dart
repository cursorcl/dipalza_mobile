import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/provider/sin_conexion_exception.dart';
import 'package:dipalza_movil/src/provider/venta_rechazada_exception.dart';
import 'package:dipalza_movil/src/utils/mensaje_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final opciones = RequestOptions(path: '/api/ventas');

  group('SinConexionException.desde', () {
    test('una falla de conexión sin respuesta del server es sin conexión', () {
      final e = DioException(requestOptions: opciones, type: DioExceptionType.connectionError);
      expect(SinConexionException.desde(e), isNotNull);
    });

    test('un tiempo agotado es sin conexión', () {
      final e = DioException(requestOptions: opciones, type: DioExceptionType.receiveTimeout);
      expect(SinConexionException.desde(e), isNotNull);
      expect(SinConexionException.desde(TimeoutException('gps')), isNotNull);
    });

    test('una respuesta de error del server no es sin conexión', () {
      final e = DioException(
          requestOptions: opciones,
          response: Response(requestOptions: opciones, statusCode: 500));
      expect(SinConexionException.desde(e), isNull);
    });
  });

  group('mensajeParaVendedor', () {
    test('sin conexión: dice que no se hizo y que revise la señal', () {
      expect(mensajeParaVendedor(const SinConexionException(), accion: 'grabar el producto'),
          'Sin conexión: no se pudo grabar el producto. Revisa la señal e intenta nuevamente.');
    });

    test('rechazo del server: muestra su motivo', () {
      expect(mensajeParaVendedor(const VentaRechazadaException('Cliente inactivo'), accion: 'grabar'),
          'Cliente inactivo');
    });

    test('otro error: mensaje genérico sin detalles técnicos', () {
      final mensaje = mensajeParaVendedor(Exception('Status: 500, Data: {...}'), accion: 'grabar el producto');
      expect(mensaje, 'No se pudo grabar el producto. Intenta nuevamente.');
    });
  });
}
