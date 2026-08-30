import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/page/ventas/venta.item.detelle.view.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../model/venta_detalle_model.dart';
import '../../share/app.navigator.dart';
import '../../share/estado.venta.dart';
import '../../widget/connectivity_banner.widget.dart';
import '../../widget/fondo.widget.dart';

class ListadoDetalleDeUnaVentaPage extends StatefulWidget {
  final VentaModel ventaModel;
  final bool esEdicion;

  const ListadoDetalleDeUnaVentaPage(
      {Key? key, required this.ventaModel, this.esEdicion = false})
      : super(key: key);

  @override
  _ListaVentasPageState createState() => _ListaVentasPageState();
}

class _ListaVentasPageState extends State<ListadoDetalleDeUnaVentaPage> {
  List<VentaDetalleModel> _detalles = [];
  bool _cargandoDetalles = true;
  Object? _errorCargaDetalles;
  late VentaModel _venta;
  int cantidadVentas = 0;

  @override
  void initState() {
    super.initState();
    _venta = widget.ventaModel;
    _cargarDetalles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.esEdicion,
        leading: widget.esEdicion
            ? null
            : BackButton(
                onPressed: () => AppNavigator.pop(),
              ),
        backgroundColor: colorRojoBase(),
        title: Text(
          'Venta #${_venta.id == -1 ? 'Nueva' : _venta.id}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: !widget.esEdicion
            ? []
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0), // Margen para que no toque los bordes
                  child: TextButton.icon(
                    onPressed: _finalizarVenta,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text("Finalizar"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
      ),
      floatingActionButton: widget.esEdicion
          ? FloatingActionButton(
              elevation: 10,
              tooltip: 'Agregar Item',
              child: const Icon(Icons.add),
              backgroundColor: colorRojoBase(),
              onPressed: () {
                _inicializarNuevaVenta(context);
              })
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _venta.id != -1
                ? RefreshIndicator(
                    onRefresh: _cargarDetalles,
                    // El hijo del RefreshIndicator es tu lista
                    child: _creaListaVentasDetalle(context),
                  )
                : _buildNuevaVenta(context),
          ),
        ],
      ), // si no hay ID → muestra inicial vacío
    );
  }

  Widget _buildNuevaVenta(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: FondoWidget()),
        Positioned.fill(
          child: Column(
            children: [
              const ConnectivityBanner(),
              Expanded(
                child: ListView(
                  children: [
                    _createEmptyCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _creaListaVentasDetalle(BuildContext context) {
    if (_cargandoDetalles) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorCargaDetalles != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 10),
            Text('Ocurrió un error al cargar: $_errorCargaDetalles',
                textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: _cargarDetalles,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      );
    }
    return Stack(children: <Widget>[
      const Positioned.fill(
        child: FondoWidget(),
      ),
      Positioned.fill(
          child: Column(
        children: <Widget>[
          const ConnectivityBanner(),
          Expanded(
              child: ListView(
                  children: _createWidgetVentasDetalleItems(
                      context, _detalles))),
        ],
      ))
    ]);
  }

  List<Widget> _createWidgetVentasDetalleItems(
      BuildContext context, List<VentaDetalleModel> listaVenta) {
    final List<Widget> _listItem = [];
    if (listaVenta.length == 0) {
      _listItem.add(_createEmptyCard());
    } else {
      listaVenta.forEach((itemVenta) {
        final slidableItem = Slidable(
          key: ValueKey(itemVenta.id),
          endActionPane: widget.esEdicion
              ? ActionPane(
                  motion: const StretchMotion(), // Un efecto visual
                  children: [
                    // --- BOTÓN ELIMINAR ---
                    SlidableAction(
                      onPressed: (context) {
                        // Llama a tu función de lógica
                        _eliminarItem(context, itemVenta);
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Eliminar',
                    ),
                    // --- BOTÓN MODIFICAR ---
                    SlidableAction(
                      onPressed: (context) {
                        // Llama a tu función de lógica
                        _modificarItem(context, itemVenta);
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Modificar',
                    ),
                  ],
                )
              : null,

          // El hijo es tu widget original
          child: VentaDetalleTile(item: itemVenta),
        );
        // ---- FIN DE LA MODIFICACIÓN ----
        _listItem.add(slidableItem);
      });
    }
    return _listItem;
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

  void _inicializarNuevaVenta(BuildContext context) {
    // Lógica para navegar a una pantalla de edición
    AppNavigator.pushNamed(AppRoutes.ventaItemEdicion,
        arguments: {'actualVenta': _venta}).then((ventaActualizada) {
      if (ventaActualizada != null) {
        setState(() {
          _venta = ventaActualizada as VentaModel;
          _detalles = _venta.detalles;
        });
      }
    });
  }

  // --- Coloca esto dentro de la clase State de tu Widget ---

  void _modificarItem(BuildContext context, VentaDetalleModel item) {
    AppNavigator.pushNamed(AppRoutes.ventaItemEdicion,
            arguments: {'actualVentaDetalle': item, 'actualVenta': _venta})
        .then((ventaActualizada) {
      if (ventaActualizada != null) {
        setState(() {
          _venta = ventaActualizada as VentaModel;
          _detalles = _venta.detalles;
        });
      }
    });
  }

  Future<void> _finalizarVenta() async {
    _venta = await VentaProvider.ventaProvider
        .cambiarEstadoVenta(_venta, EstadoVenta.FINISHED);
    AppNavigator.popUntilFirst();
  }

  void _eliminarItem(BuildContext context, VentaDetalleModel item) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content:
              Text('¿Seguro que quieres eliminar "${item.nombreProducto}"?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await VentaProvider.ventaProvider.removeItemVenta(item.id);
                _cargarDetalles();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cargarDetalles() async {
    setState(() {
      _cargandoDetalles = true;
      _errorCargaDetalles = null;
    });
    try {
      final detalles = await VentaProvider.ventaProvider
          .obtenerListaVentasDetalle(_venta.id);
      if (!mounted) return;
      setState(() {
        _detalles = detalles;
        _cargandoDetalles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCargaDetalles = e;
        _cargandoDetalles = false;
      });
    }
  }
}
