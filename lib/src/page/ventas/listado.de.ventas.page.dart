import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:dipalza_movil/src/share/estado.venta.dart';
import 'package:dipalza_movil/src/utils/filtro_ventas.dart';
import 'package:dipalza_movil/src/utils/presentacion_venta.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../share/app_routes.dart';
import '../../share/app_scaffold_key.dart';
import '../../widget/connectivity_banner.widget.dart';
import '../../widget/fondo.widget.dart';
import '../../widget/lista.widgets.dart';

class ListadeDeVentasPage extends StatefulWidget {
  const ListadeDeVentasPage({Key? key}) : super(key: key);

  @override
  _ListadoDeVentasPageState createState() => _ListadoDeVentasPageState();
}

class _ListadoDeVentasPageState extends State<ListadeDeVentasPage> {
  late Future<List<VentaModel>> _listaVentasFuture;
  int cantidadVentas = 0;
  final TextEditingController _buscarController = TextEditingController();
  bool _verBuscar = false;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  void _cerrarBuscador() {
    _buscarController.clear();
    setState(() => _verBuscar = false);
  }

  void _cargarVentas() {
    setState(() {
      _listaVentasFuture = VentaProvider.ventaProvider.obtenerListaVentas();
    });
  }

  /// Deslizar hacia abajo: se espera la respuesta antes de reemplazar el
  /// future, así la lista actual sigue a la vista mientras gira el indicador
  /// (con _cargarVentas() el FutureBuilder la cambiaría por el spinner
  /// central y el RefreshIndicator desaparecería a mitad del gesto).
  Future<void> _refrescarVentas() async {
    final ventas = await VentaProvider.ventaProvider.obtenerListaVentas();
    if (!mounted) return;
    setState(() {
      _listaVentasFuture = Future.value(ventas);
    });
  }

  Future<void> _abrirNuevaVenta() async {
    await AppNavigator.pushNamed(AppRoutes.nuevaVenta);
    _cargarVentas();
  }

  void _verDetalle(VentaModel venta) {
    AppNavigator.pushNamed(AppRoutes.ventaDetalle,
        arguments: {'ventaModel': venta, 'esEdicion': false});
  }

  void _modificarVenta(VentaModel venta) {
    AppNavigator.pushNamed(
      AppRoutes.modificarVenta,
      arguments: {'ventaEnEdicion': venta},
    ).then((_) {
      if (!mounted) return;
      _cargarVentas();
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
          'Ventas',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Buscar venta',
            onPressed: () => setState(() => _verBuscar = true),
          ),
          BotonBarra(
            icono: Icons.add,
            texto: 'Nueva Venta',
            onPressed: _abrirNuevaVenta,
          ),
        ],
      ),
      body: _creaListaVentas(context),
    );
  }

  Widget _creaListaVentas(BuildContext context) {
    return FutureBuilder(
      future: _listaVentasFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<VentaModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 10),
                const Text('Ocurrió un error al cargar:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${snapshot.error}', // Esto nos dirá la verdad
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: _cargarVentas,
                  child: const Text("Reintentar"),
                )
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final nuevaCant = snapshot.data!.length;
          // Solo si cambió, actualiza el estado del padre post-frame
          if (nuevaCant != cantidadVentas) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => cantidadVentas = nuevaCant);
            });
          }
          return Stack(children: <Widget>[
            const Positioned.fill(
              child: FondoWidget(),
            ),
            Positioned.fill(
                child: Column(
                  children: <Widget>[
                    const ConnectivityBanner(),
                    if (_verBuscar) _widgetInputBuscar(),
                    ..._widgetCuerpoLista(snapshot.data!),
                  ],
                ))
          ]);
        } else {
          return const Center(child: Text("Sin información disponible"));
        }
      },
    );
  }

  /// Resumen fijo + lista con deslizar para refrescar. Siempre scrollea
  /// (AlwaysScrollableScrollPhysics) para que el gesto funcione aunque haya
  /// pocas ventas o ninguna.
  List<Widget> _widgetCuerpoLista(List<VentaModel> ventas) {
    final filtradas = filtrarVentas(ventas, _buscarController.text);
    final Widget lista;
    if (ventas.isEmpty) {
      lista = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [_widgetSinVentas()],
      );
    } else if (filtradas.isEmpty) {
      lista = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [_widgetSinResultados()],
      );
    } else {
      lista = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: filtradas.length,
        itemBuilder: (context, i) => _widgetItemOfVenta(filtradas[i]),
      );
    }
    return [
      if (ventas.isNotEmpty) _widgetResumen(ventas.length, filtradas),
      Expanded(
        child: RefreshIndicator(onRefresh: _refrescarVentas, child: lista),
      ),
    ];
  }

  /// "20 ventas · Total $2.123.456"; con búsqueda activa, "3 de 20 ventas"
  /// y el total de las que se ven.
  Widget _widgetResumen(int cantidadTotal, List<VentaModel> filtradas) {
    final cantidad = filtradas.length == cantidadTotal
        ? '$cantidadTotal ${cantidadTotal == 1 ? 'venta' : 'ventas'}'
        : '${filtradas.length} de $cantidadTotal ventas';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(cantidad,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800)),
          const Spacer(),
          Text('Total ',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text(getValorModena(totalDeVentas(filtradas), 0),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _widgetInputBuscar() {
    return Container(
      color: colorRojoBase(),
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.search),
          title: TextField(
            controller: _buscarController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
                hintText: 'Buscar por nombre o RUT',
                border: InputBorder.none),
            onChanged: (_) => setState(() {}),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.cancel),
            tooltip: 'Cerrar búsqueda',
            onPressed: _cerrarBuscador,
          ),
        ),
      ),
    );
  }

  Widget _widgetSinResultados() {
    return EstadoVacioLista(
      icono: Icons.search_off,
      titulo: 'No hay ventas que coincidan con "${_buscarController.text.trim()}"',
      textoAccion: 'Limpiar búsqueda',
      accionPrincipal: false,
      onAccion: () => setState(() => _buscarController.clear()),
    );
  }

  Widget _widgetSinVentas() {
    return EstadoVacioLista(
      icono: Icons.receipt_long_outlined,
      titulo: 'Aún no hay ventas',
      mensaje: 'Las ventas que ingreses aparecerán aquí.',
      textoAccion: 'Nueva venta',
      onAccion: _abrirNuevaVenta,
    );
  }

  Widget _widgetItemOfVenta(VentaModel itemVenta) {
    // Facturada (CLOSED): el server la rechaza por estado (no se puede
    // modificar ni borrar), así que acá ni se ofrecen esas acciones --
    // antes se mostraban igual y el usuario recién se enteraba al chocar
    // con el error del server.
    final bool facturada = itemVenta.estadoVenta == EstadoVenta.CLOSED;

    return Slidable(
        key: ValueKey(itemVenta.id),
        endActionPane: facturada
            ? null
            : ActionPane(
                motion: const StretchMotion(), // Animación
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      _showDialogRemoveItemVenta(context, itemVenta);
                    },
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Eliminar',
                  ),
                  SlidableAction(
                    onPressed: (_) => _modificarVenta(itemVenta),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Modificar',
                  ),
                ],
              ),
        child: TarjetaLista(
          color: facturada ? Colors.green.shade50 : null,
          // Toda la tarjeta abre el detalle (antes solo la flecha).
          onTap: () => _verDetalle(itemVenta),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarIniciales(
                  iniciales: inicialesCliente(itemVenta.nombreCliente),
                  color: facturada ? Colors.green : Colors.red),
              const SizedBox(width: 12),
              Expanded(child: _widgetDatosVenta(itemVenta)),
              facturada
                  ? const SizedBox(width: anchoMenuAcciones)
                  : MenuAccionesLista(
                      tooltip: 'Acciones de la venta',
                      onModificar: () => _modificarVenta(itemVenta),
                      onEliminar: () =>
                          _showDialogRemoveItemVenta(context, itemVenta),
                    ),
            ],
          ),
        ));
  }

  Widget _widgetDatosVenta(VentaModel venta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(venta.nombreCliente,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(getFormatRut(venta.rutCliente),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            const Spacer(),
            // Alineada a la derecha, en la misma columna que el total.
            _widgetEstado(venta),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(venta.nombreCondicionVenta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ),
            const SizedBox(width: 8),
            Text(getValorModena(venta.total, 0),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      ],
    );
  }

  /// Cápsula de la venta con la hora en que quedó terminada: verde con
  /// candado si está facturada (el único estado que se marca), azul con
  /// reloj si no. Sin hora (venta nunca terminada) no se muestra nada.
  Widget _widgetEstado(VentaModel venta) {
    final texto = textoCapsulaVenta(venta);
    if (texto == null) return const SizedBox.shrink();
    final facturada = venta.estadoVenta == EstadoVenta.CLOSED;
    return Capsula(
      texto: texto,
      color: facturada ? Colors.green : Colors.blue,
      icono: facturada ? Icons.lock : Icons.schedule,
      semantica: !facturada
          ? 'Terminada a las $texto'
          : venta.fechaHoraLista == null
              ? 'Facturada'
              : 'Facturada, terminada a las $texto',
    );
  }

  Future<void> _showDialogRemoveItemVenta(BuildContext context, VentaModel venta) async {
    // Un segundo toque en "Eliminar" mientras se espera al server se ignora:
    // antes borraba dos veces y cerraba dos pantallas ("Bad state: No element").
    var eliminando = false;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    '¿Estás seguro de que deseas eliminar la venta de "${venta.nombreCliente}"?'),
                const Text('Esta acción no se puede deshacer.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                AppNavigator.pop();
              },
            ),
            TextButton(
              child:
              const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                if (eliminando) return;
                eliminando = true;
                // Se capturan antes del await: el context del diálogo puede
                // quedar desmontado mientras se espera la respuesta.
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final result =
                await VentaProvider.ventaProvider.removeVenta(venta.id);
                if (result == false) {
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                        content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    "No se ha podido eliminar la venta!!",
                                    style: TextStyle(color: Colors.white))),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                }

                // 2. Cierra el diálogo y refresca la lista
                if (navigator.canPop()) navigator.pop();
                if (!mounted) return;
                _cargarVentas();
              },
            ),
          ],
        );
      },
    );
  }
}
