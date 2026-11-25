import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/page/ventas/venta.item.detelle.view.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/share/app.formatter.dart';
import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:dipalza_movil/src/widget/error_carga.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../model/venta_detalle_model.dart';
import '../../widget/connectivity_banner.widget.dart';
import '../../widget/fondo.widget.dart';

class ListadoDetalleDeUltimaVentaPage extends StatefulWidget {
  final VentaModel? ventaModel;

  const ListadoDetalleDeUltimaVentaPage({Key? key, this.ventaModel})
      : super(key: key);

  @override
  _ListadoDetalleDeUltimaVentaPageState createState() =>
      _ListadoDetalleDeUltimaVentaPageState();
}

class _ListadoDetalleDeUltimaVentaPageState
    extends State<ListadoDetalleDeUltimaVentaPage> {
  late VentaModel? _venta;
  int cantidadVentas = 0;
  List<VentaDetalleModel> ventas = [];

  @override
  void initState() {
    super.initState();
    _venta = widget.ventaModel; // copia inicial
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              // Aquí pones tu ruta específica
              AppNavigator.pop();
            },
          ),
          backgroundColor: colorRojoBase(),
          title: Text(
            _venta!.nombreCliente,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Stack(children: <Widget>[
          const Positioned.fill(
            child: FondoWidget(),
          ),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _createHeaderVenta(),
                Expanded(
                    child: _creaListaVentasDetalle(
                        context) // si hay ID → carga desde backend
                    ),
              ],
            ),
          )
        ]));
  }

  Widget _creaListaVentasDetalle(BuildContext context) {
    return FutureBuilder(
      future: VentaProvider.ventaProvider
          .obtenerListaVentasDetalle(_venta!.id),
      builder: (BuildContext context,
          AsyncSnapshot<List<VentaDetalleModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorCarga(
            error: snapshot.error!,
            accion: 'cargar los productos de la venta',
            onReintentar: () => setState(() {}),
          );
        }
        if (snapshot.hasData) {
          return Column(
            children: <Widget>[
              const ConnectivityBanner(),
              Expanded(
                  child: ListView(
                      children: _ventasDetalleItems(context, snapshot.data!))),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  List<Widget> _ventasDetalleItems(
      BuildContext context, List<VentaDetalleModel> listaVenta) {
    final List<Widget> _listItem = [];
    if (listaVenta.length == 0) {
      _listItem.add(_createEmptyCard());
    } else {
      listaVenta.forEach((itemVenta) {
        final slidableItem = Slidable(
          key: ValueKey(itemVenta.id),
          // El hijo es tu widget original
          child: VentaDetalleTile(item: itemVenta),
        );
        // ---- FIN DE LA MODIFICACIÓN ----
        _listItem.add(slidableItem);
      });
    }
    return _listItem;
  }

  Widget _createHeaderVenta() {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Condicion de Venta',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                  _venta!.nombreCondicionVenta,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
              const SizedBox(
                height: 4,
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Descuento',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatoMoneda
                      .format(_venta!.totalDescuento),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
              const SizedBox(
                height: 4,
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Total Neto',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatoMoneda.format(_venta!.totalNeto),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
              const SizedBox(
                height: 4,
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Fecha',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatoFecha.format(_venta!.fecha),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ])));
  }

  Widget _createEmptyCard() {
    return const Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          child: Icon(Icons.insert_chart),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Sin productos agregados!!',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                )),
          ],
        ),
      ),
    );
  }
}
