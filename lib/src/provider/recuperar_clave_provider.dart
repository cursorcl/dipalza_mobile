import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/respuesta_model.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';

// Llamadas sin sesión (usuario aún no está logueado), por eso usa un Dio
// propio en vez de ApiClient().dio -- mismo patrón que VenderdorProvider.
class RecuperarClaveProvider {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final _prefs = PreferenciasUsuario();

  Future<RespuestaModel> solicitarCodigo(String usernameOrEmail) async {
    try {
      final resp = await _dio.post(
        '${_prefs.urlBase}/auth/forgot-password',
        data: {'usernameOrEmail': usernameOrEmail},
        options: Options(contentType: Headers.jsonContentType),
      );
      return RespuestaModel(status: resp.statusCode ?? 200, detalle: const {});
    } on DioException catch (e) {
      return RespuestaModel(
        status: e.response?.statusCode ?? 500,
        detalle: {"error": "No se pudo enviar el código. Intente nuevamente."},
      );
    } catch (error) {
      return RespuestaModel(
        status: 500,
        detalle: {"error": "Error en la conexión con el servidor."},
      );
    }
  }

  Future<RespuestaModel> restablecerClave(
      String username, String codigo, String claveNueva) async {
    try {
      final resp = await _dio.post(
        '${_prefs.urlBase}/auth/reset-password',
        data: {'username': username, 'codigo': codigo, 'claveNueva': claveNueva},
        options: Options(contentType: Headers.jsonContentType),
      );
      return RespuestaModel(status: resp.statusCode ?? 200, detalle: const {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return RespuestaModel(
          status: 400,
          detalle: {"error": "El código ingresado es inválido o venció."},
        );
      }
      return RespuestaModel(
        status: e.response?.statusCode ?? 500,
        detalle: {"error": "No se pudo restablecer la clave. Intente nuevamente."},
      );
    } catch (error) {
      return RespuestaModel(
        status: 500,
        detalle: {"error": "Error en la conexión con el servidor."},
      );
    }
  }
}
