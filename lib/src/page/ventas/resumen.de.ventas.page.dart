import 'package:dipalza_movil/src/model/resumen_ventas_calculator.dart';
import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:dipalza_movil/src/widget/error_carga.widget.dart';
import 'package:flutter/material.dart';

import '../../share/app_scaffold_key.dart';

class ResumenDeVentasPage extends StatefulWidget {
  const ResumenDeVentasPage({Key? key}) : super(key: key);

  @override
  _ResumenDeVentasPageState createState() => _ResumenDeVentasPageState();
}

class _ResumenDeVentasPageState extends State<ResumenDeVentasPage> {
  late Future<List<VentaModel>> _ventasFuture;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  void _cargarResumen() {
    setState(() {
      _ventasFuture = VentaProvider.ventaProvider.obtenerListaVentas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            AppScaffoldKey.homeKey.currentState?.openDrawer();
          },
        ),
        centerTitle: true,
        backgroundColor: colorRojoBase(),
        title: const Text(
          'Resumen de Venta',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _creaResumen(context),
    );
  }

  Widget _creaResumen(BuildContext context) {
    return FutureBuilder(
      future: _ventasFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<VentaModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return ErrorCarga(
              error: snapshot.error!,
              accion: 'cargar el resumen de ventas',
              onReintentar: _cargarResumen);
        } else if (snapshot.hasData) {
          final resumen = ResumenVentasCalculator.calcular(snapshot.data!);
          return ListView(
            padding: const EdgeInsets.all(12.0),
            children: [
              _tarjetaResumen('Cantidad de Ventas',
                  resumen.cantidadVentas.toString(), Icons.list_alt),
              _tarjetaResumen('Total Neto',
                  getValorModena(resumen.totalNeto, 0), Icons.attach_money),
              _tarjetaResumen('Total Descuentos',
                  getValorModena(resumen.totalDescuento, 0), Icons.percent),
              _tarjetaResumen('Total IVA',
                  getValorModena(resumen.totalIva, 0), Icons.receipt_long),
              _tarjetaResumen('Total ILA',
                  getValorModena(resumen.totalIla, 0), Icons.request_quote),
              _tarjetaResumen('Total Bruto',
                  getValorModena(resumen.totalBruto, 0), Icons.payments),
            ],
          );
        } else {
          return const Center(child: Text("Sin información disponible"));
        }
      },
    );
  }

  Widget _tarjetaResumen(String titulo, String valor, IconData icono) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorRojoBase(),
          foregroundColor: Colors.white,
          child: Icon(icono),
        ),
        title: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.normal)),
        trailing: Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
