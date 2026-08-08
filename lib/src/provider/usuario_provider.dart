import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/respuesta_model.dart';

import '../services/api_client.dart';

class UsuarioProvider {
  final _dio = ApiClient().dio;

  Future<RespuestaModel> cambiarClave(String claveActual, String claveNueva) async {
    try {
      final resp = await _dio.put(
        '/api/usuario/cambiar-clave',
        data: {'claveActual': claveActual, 'claveNueva': claveNueva},
        options: Options(contentType: Headers.jsonContentType),
      );
      return RespuestaModel(status: resp.statusCode ?? 200, detalle: const {});
    } on DioException catch (e) {
      if (e.response == null) {
        return RespuestaModel(
          status: 500,
          detalle: {"error": "Error en la conexión con el servidor."},
        );
      }
      switch (e.response!.statusCode) {
        case 401:
          return RespuestaModel(
            status: 401,
            detalle: {"error": "La clave actual es incorrecta."},
          );
        case 400:
          return RespuestaModel(
            status: 400,
            detalle: {"error": "La clave nueva no es válida."},
          );
        default:
          return RespuestaModel(
            status: e.response!.statusCode ?? 500,
            detalle: {"error": "No se pudo cambiar la clave. Intente nuevamente."},
          );
      }
    } catch (error) {
      return RespuestaModel(
        status: 500,
        detalle: {"error": "Error en la conexión con el servidor."},
      );
    }
  }
}
