import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/page/ventas/venta.item.detelle.view.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/provider/venta_rechazada_exception.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/utils/alert_util.dart' as alertUtil;
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../model/venta_detalle_model.dart';
import '../../share/app.navigator.dart';
import '../../share/estado.venta.dart';
import '../../widget/connectivity_banner.widget.dart';
import '../../widget/fondo.widget.dart';
import '../../widget/lista.widgets.dart';

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
  bool _finalizando = false;

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
        leadingWidth: widget.esEdicion ? 140 : null,
        leading: widget.esEdicion
            ? BotonBarra(
                icono: Icons.add,
                texto: 'Agregar',
                onPressed: () => _inicializarNuevaVenta(context),
              )
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
                BotonBarra(
                  icono: Icons.check_circle_outline,
                  texto: _finalizando ? 'Finalizando...' : 'Finalizar',
                  onPressed: _finalizando ? null : _finalizarVenta,
                  iconoPersonalizado: _finalizando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
      ),
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
              child: _detalles.isEmpty
                  ? ListView(
                      // Permite deslizar para refrescar aunque esté vacía.
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_createEmptyCard()])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: _detalles.length,
                      itemBuilder: (context, i) =>
                          _widgetItemDetalle(context, _detalles[i]))),
        ],
      ))
    ]);
  }

  Widget _widgetItemDetalle(BuildContext context, VentaDetalleModel itemVenta) {
    return Slidable(
      key: ValueKey(itemVenta.id),
      endActionPane: widget.esEdicion
          ? ActionPane(
              motion: const StretchMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => _eliminarItem(context, itemVenta),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Eliminar',
                ),
                SlidableAction(
                  onPressed: (context) => _modificarItem(context, itemVenta),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Modificar',
                ),
              ],
            )
          : null,
      // En edición, el menú ⋮ ofrece las mismas acciones que el deslizar y
      // tocar la tarjeta abre la modificación.
      child: VentaDetalleTile(
        item: itemVenta,
        onModificar:
            widget.esEdicion ? () => _modificarItem(context, itemVenta) : null,
        onEliminar:
            widget.esEdicion ? () => _eliminarItem(context, itemVenta) : null,
      ),
    );
  }

  Widget _createEmptyCard() {
    return EstadoVacioLista(
      icono: Icons.shopping_basket_outlined,
      titulo: 'Aún no hay productos en esta venta',
      mensaje: widget.esEdicion
          ? 'Agrega el primer producto para comenzar.'
          : null,
      textoAccion: widget.esEdicion ? 'Agregar producto' : null,
      onAccion: widget.esEdicion ? () => _inicializarNuevaVenta(context) : null,
    );
  }

  void _inicializarNuevaVenta(BuildContext context) {
    // Lógica para navegar a una pantalla de edición
    AppNavigator.pushNamed(AppRoutes.ventaItemEdicion,
        arguments: {'actualVenta': _venta}).then((ventaActualizada) {
      // Solo una venta: si vuelve otra cosa (p. ej. un producto de una pantalla
      // cerrada de más), se ignora en vez de caerse la app.
      if (ventaActualizada is VentaModel) {
        setState(() {
          _venta = ventaActualizada;
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
      // Solo una venta: si vuelve otra cosa (p. ej. un producto de una pantalla
      // cerrada de más), se ignora en vez de caerse la app.
      if (ventaActualizada is VentaModel) {
        setState(() {
          _venta = ventaActualizada;
          _detalles = _venta.detalles;
        });
      }
    });
  }

  Future<void> _finalizarVenta() async {
    setState(() => _finalizando = true);
    try {
      _venta = await VentaProvider.ventaProvider
          .cambiarEstadoVenta(_venta, EstadoVenta.FINISHED);
      AppNavigator.popUntilFirst();
    } catch (e) {
      if (!mounted) return;
      setState(() => _finalizando = false);
      await alertUtil.showAlertDialog(
        context,
        'No se pudo finalizar la venta. Revisa tu conexión e intenta nuevamente.',
        Icons.error_outline,
      );
    }
  }

  void _eliminarItem(BuildContext context, VentaDetalleModel item) {
    var eliminando = false;
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
                // Un segundo toque mientras el diálogo se cierra cerraba
                // también esta pantalla.
                if (eliminando) return;
                eliminando = true;
                // Se captura antes del await y con el context de la página:
                // el [context] recibido es el de la acción deslizable, que ya
                // puede estar desmontada cuando responde el server.
                final messenger = ScaffoldMessenger.of(this.context);
                Navigator.of(ctx).pop();
                try {
                  await VentaProvider.ventaProvider.removeItemVenta(item.id);
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text(e is VentaRechazadaException
                        ? e.mensaje
                        : 'No se pudo eliminar el ítem: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
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
