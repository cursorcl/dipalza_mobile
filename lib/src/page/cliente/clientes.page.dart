import 'package:dipalza_movil/src/bloc/clientes_bloc.dart';
import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/utils/filtro_clientes.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:dipalza_movil/src/widget/fondo.widget.dart';
import 'package:flutter/material.dart';

import '../../share/app.navigator.dart';
import '../../share/app_scaffold_key.dart';
import '../../utils/presentacion_venta.dart';
import '../../widget/connectivity_banner.widget.dart';
import '../../widget/lista.widgets.dart';

class ClientesPage extends StatefulWidget {
  final bool isForSelection;

  /// Título de la barra ("Clientes" por defecto).
  final String titulo;

  /// Si viene, tocar un cliente lo entrega por aquí en vez de cerrar la
  /// página: así otra pantalla del menú (Últimas Ventas) usa esta lista como
  /// su primer paso, con ☰ y sin flecha de volver.
  final ValueChanged<ClientesModel>? onSeleccionado;

  const ClientesPage(
      {Key? key,
      this.isForSelection = false,
      this.titulo = 'Clientes',
      this.onSeleccionado})
      : super(key: key);

  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClientesBloc _clientesBloc = ClientesBloc();
  TextEditingController controller = new TextEditingController();
  bool _verBuscar = false;

  @override
  void initState() {
    super.initState();
    _clientesBloc.ensureFresh();
  }

  Future<void> getListaClientesRefrescar() => _clientesBloc.forceRefresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            widget.isForSelection ? Icons.arrow_back : Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            if (widget.isForSelection) {
              AppNavigator.pop();
            } else {
              AppScaffoldKey.homeKey.currentState?.openDrawer();
            }
          },
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: colorRojoBase(),
        title: Container(
          child: Center(
            child: Text(
              widget.titulo,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
            onPressed: () {
              setState(() {
                _verBuscar = true;
              });
            },
          ),
        ],
      ),
      body: Stack(children: <Widget>[
        const Positioned.fill(
          child: FondoWidget(),
        ),
        Positioned.fill(
          child: Column(
            children: <Widget>[
              const ConnectivityBanner(),
              _verBuscar ? _creaInputBuscar(context) : Container(),
              Expanded(
                child: StreamBuilder<List<ClientesModel>>(
                  stream: _clientesBloc.clientesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final listaCompleta = snapshot.data ?? [];
                    final listaAMostrar = _filtrarLista(listaCompleta);
                    return _creaListaClientes(context, listaAMostrar);
                  },
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  List<ClientesModel> _filtrarLista(List<ClientesModel> listaCompleta) {
    if (controller.text.isEmpty) return listaCompleta;
    return listaCompleta
        .where((cliente) => coincideCliente(cliente, controller.text))
        .toList();
  }

  Widget _creaInputBuscar(BuildContext context) {
    return AnimatedOpacity(
      opacity: _verBuscar ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        color: colorRojoBase(),
        child: new Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Card(
            child: new ListTile(
              leading: const Icon(Icons.search),
              title: new TextField(
                controller: controller,
                decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, código o RUT', border: InputBorder.none),
                onChanged: onSearchTextChanged,
              ),
              trailing: new IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  controller.clear();
                  onSearchTextChanged('');
                  setState(() {
                    _verBuscar = false;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  onSearchTextChanged(String text) {
    setState(() {});
  }

  Widget _creaListaClientes(
      BuildContext context, List<ClientesModel> listaCliente) {
    if (listaCliente.length == 0) {
      return RefreshIndicator(
          onRefresh: getListaClientesRefrescar, child: _createEmptyCard());
    }

    return RefreshIndicator(
      onRefresh: getListaClientesRefrescar,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: listaCliente.length,
        itemBuilder: (context, i) {
          return _creaCard(listaCliente[i]);
        },
      ),
    );
  }

  Widget _createEmptyCard() {
    return ListView(
      // Permite deslizar para refrescar aunque no haya clientes.
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        EstadoVacioLista(
          icono: Icons.people_outline,
          titulo: 'No tienes clientes asignados',
          mensaje: 'Contacta a administración si esto no es correcto.',
        ),
      ],
    );
  }

  Future<void> _verUltimaVenta(ClientesModel cliente) async {
    try {
      var ventaModel =
          await VentaProvider.ventaProvider.obtenerUltimaVenta(cliente);
      if (!mounted) return;
      if (ventaModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este cliente no tiene ventas asociadas.'),
            duration: Duration(seconds: 2),
          ),
        );
        return; // No navega
      }
      AppNavigator.pushNamed(AppRoutes.listadoUltimaVenta,
          arguments: {'ventaModel': ventaModel});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar la operación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _creaCard(ClientesModel cliente) {
    final estiloSecundario =
        TextStyle(fontSize: 14, color: Colors.grey.shade700);
    return TarjetaLista(
      // Al elegir cliente (para una venta o para Últimas Ventas), tocar la
      // tarjeta lo selecciona.
      onTap: widget.onSeleccionado != null
          ? () => widget.onSeleccionado!(cliente)
          : widget.isForSelection
              ? () => AppNavigator.pop(cliente)
              : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarIniciales(iniciales: inicialesCliente(cliente.razon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cliente.razon.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(getFormatRut(cliente.rut), style: estiloSecundario),
                // Dirección y teléfono solo si vienen: antes un dato vacío
                // dejaba una línea en blanco.
                if (cliente.direccion.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _lineaConIcono(Icons.place_outlined,
                      cliente.direccion.trim(), estiloSecundario),
                ],
                if (cliente.telefono.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _lineaConIcono(Icons.phone_outlined,
                      cliente.telefono.trim(), estiloSecundario),
                ],
              ],
            ),
          ),
          // En Últimas Ventas tocar el cliente ya muestra sus ventas: el
          // botón de historial sobra.
          if (widget.onSeleccionado == null)
            IconButton(
              icon: Icon(Icons.history, color: Colors.grey.shade700),
              tooltip: 'Ver última venta',
              onPressed: () => _verUltimaVenta(cliente),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _lineaConIcono(IconData icono, String texto, TextStyle estilo) {
    return Row(
      children: [
        Icon(icono, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(texto,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo),
        ),
      ],
    );
  }
}
