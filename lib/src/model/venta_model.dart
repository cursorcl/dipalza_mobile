import 'dart:convert';

import 'package:dipalza_movil/src/model/venta_detalle_model.dart';
import 'package:dipalza_movil/src/share/estado.venta.dart';

class VentaModel {
  VentaModel(
      {this.id = -1,
      required this.fecha,
      required this.rutCliente,
      this.codigoCliente = "   ",
      this.nombreCliente = "",
      required this.codigoVendedor,
      this.tipoVendedor = "1",
      this.nombreVendedor = "",
      required this.codigoRuta,
      this.nombreRuta = "",
      required this.codigoCondicionVenta,
      this.nombreCondicionVenta = "",
      this.totalDescuento = 0,
      this.totalIla = 0,
      this.totalIva = 0,
      this.totalNeto = 0,
      this.total = 0,
      this.detalles = const [],
      this.estadoVenta = EstadoVenta.OPENED,
      this.fechaHoraLista});
  int id;
  DateTime fecha;

  /// Hora en que la venta pasó a Terminada (hora de Chile, la fija el
  /// server). Null si nunca se terminó. Solo lectura: no va en toMap().
  DateTime? fechaHoraLista;

  String rutCliente;
  String codigoCliente;
  String nombreCliente;

  String codigoVendedor;
  String tipoVendedor;
  String nombreVendedor;
  String codigoRuta;
  String nombreRuta;
  String codigoCondicionVenta;
  String nombreCondicionVenta;
  double totalDescuento;
  double totalIla;
  double totalIva;
  double totalNeto;
  double total;
  List<VentaDetalleModel> detalles;
  EstadoVenta estadoVenta;

  factory VentaModel.fromMap(Map<String, dynamic> json) => VentaModel(
      id: json["id"] == null ? 0 : json["id"],
      fecha: DateTime.parse(json["fecha"]),
      rutCliente: json["rutCliente"],
      codigoCliente: json["codigoCliente"],
      nombreCliente: json["nombreCliente"] == null ? "" : json["nombreCliente"],
      codigoVendedor: json["codigoVendedor"],
      tipoVendedor: json["tipoVendedor"],
      nombreVendedor: json['nombreVendedor'],
      codigoRuta: json["codigoRuta"],
      nombreRuta: json["nombreRuta"],
      codigoCondicionVenta: json["codigoCondicionVenta"],
      nombreCondicionVenta: json["nombreCondicionVenta"],
      totalNeto: json["totalNeto"].toDouble(),
      total: json["total"].toDouble(),
      totalDescuento: json["totalDescuento"].toDouble(),
      totalIla: json["totalIla"].toDouble(),
      totalIva: json["totalIva"].toDouble(),
      detalles: (json['detalles'] as List?)
              ?.map(
                  (e) => VentaDetalleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      estadoVenta: estadoVentaFromApi(json["estadoVenta"]),
      fechaHoraLista: json["fechaHoraLista"] == null
          ? null
          : DateTime.tryParse(json["fechaHoraLista"]));

  Map<String, dynamic> toMap() => {
        "id": id,
        "fecha": fecha.toIso8601String(),
        "rutCliente": rutCliente,
        "codigoCliente": codigoCliente,
        "nombreCliente": nombreCliente,
        "codigoVendedor": codigoVendedor,
        "tipoVendedor": tipoVendedor,
        "nombreVendedor": nombreVendedor,
        "codigoRuta": codigoRuta,
        "nombreRuta": nombreRuta,
        "codigoCondicionVenta": codigoCondicionVenta,
        "nombreCondicionVenta": nombreCondicionVenta,
        "totalNeto": totalNeto,
        "total": total,
        "totalDescuento": totalDescuento,
        "totalIla": totalIla,
        "totalIva": totalIva,
        'detalles': detalles.map((d) => d.toJson()).toList(),
        "estadoVenta": estadoVenta.name
      };

  static String toJson(VentaModel ventaModel) {
    return json.encode(ventaModel.toMap());
  }

  static VentaModel fromJson(String str) =>
      VentaModel.fromMap(json.decode(str));
  // Para lista de ventas
  static List<VentaModel> listFromJson(String str) =>
      List<VentaModel>.from(json.decode(str).map((x) => VentaModel.fromMap(x)));
}
