import 'package:dio/dio.dart';

import '../model/tablero_meta_model.dart';
import '../services/api_client.dart';

/// El usuario autenticado no tiene un vendedor asociado (HTTP 404).
class MetaSinVendedorException implements Exception {
  final String mensaje;

  const MetaSinVendedorException(this.mensaje);

  @override
  String toString() => mensaje;
}

const _mensajeSinVendedor = 'El usuario no tiene un vendedor asociado.';

class MetaProvider {
  static final MetaProvider metaProvider = MetaProvider();

  final Dio _dio;

  MetaProvider({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  /// Meta y ventas del mes del vendedor autenticado (el server lo toma del token).
  Future<TableroMetaModel> obtenerMiMeta() async {
    try {
      final response = await _dio.get('/api/metas/mia');
      return TableroMetaModel.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final data = e.response?.data;
        final mensaje = data is Map && data['message'] is String ? data['message'] as String : '';
        throw MetaSinVendedorException(
            mensaje.trim().isEmpty ? _mensajeSinVendedor : mensaje);
      }
      rethrow;
    }
  }
}
