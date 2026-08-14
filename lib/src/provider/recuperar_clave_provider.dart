import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/respuesta_model.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';

// Llamada sin sesión (usuario aún no está logueado), por eso usa un Dio
// propio en vez de ApiClient().dio -- mismo patrón que VenderdorProvider.
class RecuperarClaveProvider {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final _prefs = PreferenciasUsuario();

  Future<RespuestaModel> solicitarRecuperacion(String usernameOrEmail) async {
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
        detalle: {"error": "No se pudo enviar la solicitud. Intente nuevamente."},
      );
    } catch (error) {
      return RespuestaModel(
        status: 500,
        detalle: {"error": "Error en la conexión con el servidor."},
      );
    }
  }
}
