import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/login.model.dart';
import 'package:dipalza_movil/src/model/respuesta_model.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:dipalza_movil/src/utils/utils.dart';

class VenderdorProvider {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<RespuestaModel> loginUsuario(String usuario, String password) async {
    final prefs = PreferenciasUsuario();
    final login = LoginModel();
    // login.username = getFormatRutToService(usuario);
    login.username = usuario;
    login.password = password;

    try {
      final resp = await _dio.post(
        '${prefs.urlBase}/auth/login',
        data: loginModelToJson(login),
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      final respData = resp.data;
      return RespuestaModel(
        status: resp.statusCode ?? 200,
        detalle: respData is Map<String, dynamic>
            ? respData
            : {"error": respData?.toString() ?? "Respuesta inesperada"},
      );
    } on DioException catch (e) {
      if (e.response == null) {
        return RespuestaModel(
          status: 500,
          detalle: {"error": "Error en la conexión del servicio de Autenticación."},
        );
      }

      switch (e.response!.statusCode) {
        case 401:
          return RespuestaModel(
            status: 401,
            detalle: {"error":"Las credenciales son incorrectas."}
          );
        case 409:
          return RespuestaModel(
            status: 409,
            detalle: {"error":"Usuario con actividad en otro dispositivo"},
          );
        case 402:
          return RespuestaModel(
            status: 402,
            detalle: {"error": "La versión de prueba ha finalizado."},
          );
        default:
          final data = e.response?.data;
          // Spring devuelve "error" (frase genérica del código HTTP, p.ej.
          // "Unprocessable Entity") y "message" (el motivo real, cuando
          // server.error.include-message está habilitado) como campos
          // separados -- se prioriza "message" para mostrar algo útil.
          final mensaje = data is Map<String, dynamic>
              ? (data['message'] ?? data['error'])?.toString() ?? "Error desconocido"
              : data?.toString() ?? "Error desconocido";
          return RespuestaModel(
            status: e.response!.statusCode ?? 500,
            detalle: {"error": mensaje},
          );
      }
    } catch (error) {
      return RespuestaModel(
        status: 500,
        detalle: {"error": "Error en la conexión del servicio de Autenticación."},
      );
    }
  }
}
