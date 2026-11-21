import 'dart:developer' as developer;
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';

import '../services/api_client.dart';

class ClientesProvider {
  static final ClientesProvider clientesProvider = ClientesProvider._();
  final _dio = ApiClient().dio;

  ClientesProvider._() {}

  Future<List<ClientesModel>> obtenerListaClientes(
      String codVendedor, String codRuta) async {
    try {
      final response = await _dio.get('/api/clientes/vendedor', queryParameters: {'codigoVendedor': codVendedor});
      final List<dynamic> data = response.data;
      return data.map((json) => ClientesModel.fromJson(json)).toList();
    } catch (error) {
      developer.log('Error al consultar clientes', name: 'ClientesProvider', error: error);
      rethrow;
    }
  }

  Future<List<ClientesModel>> obtenerListaClientesv2() async {
    final prefs = PreferenciasUsuario();

    try {
      final response = await _dio.get(
        '/clients/seller/${prefs.vendedor}/route/${prefs.ruta}',
        options: Options(
          headers: {'Accept-Charset': 'utf-8'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => ClientesModel.fromJson(json)).toList();
        }
        return clientesModelFromJson(jsonEncode(data));
      }
      return clientesModelFromJson('[]');
    } catch (error) {
      developer.log('Error al consultar clientes', name: 'ClientesProvider', error: error);
      return clientesModelFromJson('[]');
    }
  }

  Future<ClientesModel> obtenerClienteByRutCodigo(
      String rut, String codigo) async {
    try {
      final response = await _dio.get(
        '/api/clientes/$rut',
        queryParameters: codigo.trim().isNotEmpty ? {'codigo': codigo} : null,
        options: Options(
          headers: {'Accept-Charset': 'utf-8'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        return ClientesModel.fromJson(response.data);
      }
      return clienteModelFromJson('{}');
    } catch (error) {
      developer.log('Error al consultar clientes', name: 'ClientesProvider', error: error);
      return clienteModelFromJson('{}');
    }
  }
}
