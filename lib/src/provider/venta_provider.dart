import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/model/venta_detalle_model.dart';
import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/provider/venta_rechazada_exception.dart';
import 'package:dipalza_movil/src/share/estado.venta.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';

import '../model/numerado_model.dart';
import '../services/api_client.dart';

class VentaProvider {
  static final VentaProvider ventaProvider = VentaProvider._();
  final _dio = ApiClient().dio;

  VentaProvider._() {
    //
  }

  /* ================= GRABAR =================== */

  Future<VentaModel> saveVentaEncabezado(VentaModel ventaModel) async {
    try {
      final response = await _dio.post(
        '/api/ventas/encabezado',
        data: VentaModel.toJson(ventaModel),
      );

      return VentaModel.fromMap(response.data);
    } on DioException catch (e) {
      developer.log("No se ha grabado la venta ${ventaModel}");
      final rechazo = VentaRechazadaException.desde(e);
      if (rechazo != null) throw rechazo;

      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception("Error al garabar la venta $ventaModel. "
          "Status: $statusCode, "
          "Data: $data, "
          "Mensaje Dio: ${e.message}");
    }
  }

  Future<VentaModel> saveVenta(VentaModel ventaModel) async {
    try {
      final response = await _dio.post(
        '/api/ventas',
        data: VentaModel.toJson(ventaModel),
      );

      return VentaModel.fromMap(response.data);
    } on DioException catch (e) {
      developer.log("No se ha grabado la venta ${ventaModel}");
      final rechazo = VentaRechazadaException.desde(e);
      if (rechazo != null) throw rechazo;

      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception("Error al garabar la venta $ventaModel. "
          "Status: $statusCode, "
          "Data: $data, "
          "Mensaje Dio: ${e.message}");
    }
  }

  Future<VentaModel> saveItemVenta(VentaDetalleModel registro) async {

    try {
      final response = await _dio.post(
        '/api/ventas/detalleVenta',
        data: ventaDetalleModelToJson(registro),
      );
      return VentaModel.fromMap(response.data);
    } on DioException catch (e) {
      developer.log("No se ha grabado el detalle de venta ${registro}");
      final rechazo = VentaRechazadaException.desde(e);
      if (rechazo != null) throw rechazo;

      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception("Error al garabar el detalle venta $registro. "
          "Status: $statusCode, "
          "Data: $data, "
          "Mensaje Dio: ${e.message}");
    }
  }

  Future<bool> removeVenta(int ventaId) async {


    try {
      await _dio.delete('/api/ventas/${ventaId}');
      return true;
    } catch (error) {
      developer.log("No se ha eliminado el item de venta ${ventaId}");
      return false;
    }
  }

  Future<void> removeItemVenta(int itemVentaId) async {

    try {
      await _dio.delete('/api/ventas/eliminarItemVenta/${itemVentaId}');

      return;
    } on DioException catch (e) {
      developer.log("No se ha eliminado el item de venta ${itemVentaId}");
      final rechazo = VentaRechazadaException.desde(e);
      if (rechazo != null) throw rechazo;

      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception("Error eliminando item $itemVentaId. "
          "Status: $statusCode, "
          "Data: $data, "
          "Mensaje Dio: ${e.message}");
    }
  }

  Future<List<VentaModel>> obtenerListaVentas() async {

    final prefs = new PreferenciasUsuario();
    var fechaFacturacion =
        prefs.fechaFacturacion.toIso8601String().split('T').first;
    try {
      final response = await _dio.get(
          '/api/ventas/vendedor/${prefs.vendedor}/fecha',
          queryParameters: {'fecha': fechaFacturacion});

      final List<dynamic> data = response.data;

      return data.map((json) => VentaModel.fromMap(json)).toList();
    } on DioException catch (e) {
      developer.log(
          "No se ha podido obtener la ventas para el vendedor ${prefs.vendedor} el día ${fechaFacturacion}  ",
          error: e);
    }
    return [];
  }

  /**
   * Obtiene el detalle de productos asociados a una venta.
   * @param ventaId El ID de la venta para la cual se obtendrán los detalles.
   */
  Future<List<VentaDetalleModel>> obtenerListaVentasDetalle(int ventaId) async {
    try {
      final response = await _dio.get('/api/ventas/${ventaId}/detalles');

      final List<dynamic> data = response.data;

      return data.map((json) => VentaDetalleModel.fromJson(json)).toList();
    } on DioException catch (e) {
      developer.log("Ocurrió un error al cargar las ventas detalle.  ",
          error: e);
    }
    return [];
  }

  Future<NumeradoModel> actualizarNumerado(NumeradoModel numerado) async {
    try {
      final response = await _dio.post('/api/ventas/updateNumerado',
          data: numeradoModelToJson(numerado));
      return numeradoModelFromJson(response.data);
    } on DioException catch (e) {
      developer.log(
          "No se ha podido actualizar el estado del numerado:" + e.toString());

      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception("No se ha podido actualizar el estado del numerado "
          "Status: $statusCode, "
          "Data: $data, "
          "Mensaje Dio: ${e.message}");
    }
  }

  Future<VentaModel?> obtenerUltimaVenta(ClientesModel cliente) async {
    try {
      final clientIdQuery = {"rut": cliente.rut, "codigo": cliente.codigo};
      final response = await _dio.post('/api/ventas/ultimaventacliente',
          data: jsonEncode(clientIdQuery));

      return VentaModel.fromMap(response.data);
    } on DioException catch (e) {
      // Si el servidor responde con 404, lo tratamos como "sin ventas" (null)
      if (e.response?.statusCode == 404) {
        return null;
      }

      // Cualquier otro error (500, timeout, 403) sí es una excepción técnica
      developer.log(
        "Error técnico al obtener venta de ${cliente.razon}",
        error: e,
      );
      throw Exception("Error de comunicación con el servidor (Código: ${e.response?.statusCode})");
    }
  }

  Future<List<VentaModel>> obtenerUltimasVentasDeCliente(
      ClientesModel cliente) async {
    try {
      final clientIdQuery = {"rut": cliente.rut, "codigo": cliente.codigo};
      final response = await _dio.post('/api/ventas/ultimasventascliente',
          data: jsonEncode(clientIdQuery));

      final List<dynamic> data = response.data;
      return data.map((json) => VentaModel.fromMap(json)).toList();
    } on DioException catch (e) {
      developer.log(
        "Error técnico al obtener últimas ventas de ${cliente.razon}",
        error: e,
      );
      throw Exception(
          "Error de comunicación con el servidor (Código: ${e.response?.statusCode})");
    }
  }

  Future<VentaModel> cambiarEstadoVenta(
      VentaModel venta, EstadoVenta estadoVenta) async {

    try {
      final estadoVentaQuery = {
        "idVenta": venta.id,
        "estadoVenta": estadoVenta.name
      };
      final response = await _dio.post('/api/ventas/updateEstadoVenta',
          data: jsonEncode(estadoVentaQuery));

      return VentaModel.fromMap(response.data);
    } on DioException catch (e) {
      developer.log(
          "Se ha producido un error al actualiar el estado de la venta ${venta.id}",
          error: e);
      throw Exception(
          "Se ha producido un error al actualiar el estado de la ventae ${venta.id}: ${e}");
    }
  }
}
