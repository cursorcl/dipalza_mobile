import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dipalza_movil/src/provider/venta_rechazada_exception.dart';

DioException _error(int status, dynamic data) {
  final opciones = RequestOptions(path: '/api/ventas/encabezado');
  return DioException(
    requestOptions: opciones,
    response: Response(requestOptions: opciones, statusCode: status, data: data),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('VentaRechazadaException.desde', () {
    test('un 409 con message devuelve la excepción con ese texto', () {
      final e = VentaRechazadaException.desde(_error(409, {
        'message': 'El cliente está inactivo: no se pueden crear ni modificar sus ventas.'
      }));

      expect(e, isNotNull);
      expect(e!.mensaje,
          'El cliente está inactivo: no se pueden crear ni modificar sus ventas.');
      expect(e.toString(), e.mensaje);
    });

    test('un 409 sin cuerpo devuelve null', () {
      expect(VentaRechazadaException.desde(_error(409, null)), isNull);
    });

    test('un 409 con message vacío devuelve null', () {
      expect(VentaRechazadaException.desde(_error(409, {'message': '  '})), isNull);
    });

    test('otro status devuelve null aunque traiga message', () {
      expect(VentaRechazadaException.desde(_error(500, {'message': 'falla'})), isNull);
    });

    test('un error sin respuesta (sin red) devuelve null', () {
      final sinRespuesta = DioException(
        requestOptions: RequestOptions(path: '/api/ventas'),
        type: DioExceptionType.connectionError,
      );
      expect(VentaRechazadaException.desde(sinRespuesta), isNull);
    });
  });
}
