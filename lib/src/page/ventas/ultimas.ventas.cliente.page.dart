import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/share/app.formatter.dart';
import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:dipalza_movil/src/widget/error_carga.widget.dart';
import 'package:flutter/material.dart';

import '../../share/app_scaffold_key.dart';
import '../cliente/clientes.page.dart';

class UltimasVentasClientePage extends StatefulWidget {
  const UltimasVentasClientePage({Key? key}) : super(key: key);

  @override
  _UltimasVentasClientePageState createState() =>
      _UltimasVentasClientePageState();
}

class _UltimasVentasClientePageState extends State<UltimasVentasClientePage> {
  ClientesModel? _cliente;
  Future<List<VentaModel>>? _ventasFuture;

  // Antes, al abrir la pantalla se empujaba la página de selección de
  // clientes (con flecha de volver) y, al volver, quedaba una pantalla casi
  // vacía. Ahora la lista de clientes es el primer paso de esta misma
  // pantalla, con ☰ como las demás opciones del menú.

  void _cambiarCliente() => setState(() {
        _cliente = null;
        _ventasFuture = null;
      });

  void _seleccionarCliente(ClientesModel cliente) {
    setState(() {
      _cliente = cliente;
      _ventasFuture =
          VentaProvider.ventaProvider.obtenerUltimasVentasDeCliente(cliente);
    });
  }

  void _reintentar() {
    if (_cliente == null) return;
    setState(() {
      _ventasFuture = VentaProvider.ventaProvider
          .obtenerUltimasVentasDeCliente(_cliente!);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cliente == null) {
      return ClientesPage(
          titulo: 'Últimas Ventas', onSeleccionado: _seleccionarCliente);
    }
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
        title: Text(
          _cliente!.razon.trim(),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'Cambiar cliente',
            onPressed: _cambiarCliente,
          ),
        ],
      ),
      body: _creaConCliente(),
    );
  }

  Widget _creaConCliente() {
    return FutureBuilder<List<VentaModel>>(
      future: _ventasFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<VentaModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorCarga(
              error: snapshot.error!,
              accion: 'cargar las ventas del cliente',
              onReintentar: _reintentar);
        }
        final ventas = snapshot.data ?? [];
        if (ventas.isEmpty) {
          return const Center(
            child: Text('Este cliente no tiene ventas facturadas.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12.0),
          children: ventas.map((venta) => _tarjetaVenta(venta)).toList(),
        );
      },
    );
  }

  Widget _tarjetaVenta(VentaModel venta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => AppNavigator.pushNamed(AppRoutes.listadoUltimaVenta,
            arguments: {'ventaModel': venta}),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatoFecha.format(venta.fecha),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Divider(),
              _filaMonto('Neto', venta.totalNeto),
              _filaMonto('IVA', venta.totalIva),
              _filaMonto('ILA', venta.totalIla),
              _filaMonto('Descuento', venta.totalDescuento),
              _filaMonto('Total', venta.total, destacado: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaMonto(String etiqueta, double valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(etiqueta,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const Spacer(),
          Text(
            AppFormatters.formatoMoneda.format(valor),
            style: TextStyle(
              fontSize: destacado ? 16 : 14,
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
