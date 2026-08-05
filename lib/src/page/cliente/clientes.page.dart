import 'package:dipalza_movil/src/bloc/clientes_bloc.dart';
import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:dipalza_movil/src/widget/fondo.widget.dart';
import 'package:flutter/material.dart';

import '../../share/app.navigator.dart';
import '../../share/app_scaffold_key.dart';
import '../../widget/connectivity_banner.widget.dart';

class ClientesPage extends StatefulWidget {
  final bool isForSelection;

  const ClientesPage({Key? key, this.isForSelection = false}) : super(key: key);

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
          child: const Center(
            child: Text(
              'Clientes',
              style: TextStyle(color: Colors.white),
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
        .where((cliente) => cliente.razon.contains(controller.text))
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
                    hintText: 'Buscar', border: InputBorder.none),
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
    if (listaCliente.length == 0) return _createEmptyCard();

    return RefreshIndicator(
      onRefresh: getListaClientesRefrescar,
      child: ListView.builder(
        itemCount: listaCliente.length,
        itemBuilder: (context, i) {
          return _creaCard(listaCliente[i]);
        },
      ),
    );
  }

  _createEmptyCard() {
    return Card(
        child: ListTile(
      leading: CircleAvatar(
        radius: 25,
        child: const Icon(Icons.account_box),
        backgroundColor: colorRojoBase(),
        foregroundColor: Colors.white,
      ),
      title: const Text(
          'No tienes clientes asignados. Contacta a administración si esto no es correcto.'),
    ));
  }

  _creaCard(ClientesModel cliente) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          child: const Icon(Icons.account_box),
          backgroundColor: colorRojoBase(),
          foregroundColor: Colors.white,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(cliente.razon,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                )),
            const SizedBox(
              height: 2.0,
            ),
            Text(getFormatRut(cliente.rut),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                )),
            const SizedBox(
              height: 5.0,
            )
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(cliente.direccion, style: const TextStyle(fontSize: 12.0)),
            Text(cliente.telefono, style: const TextStyle(fontSize: 12.0))
          ],
        ),
        trailing: IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined),
            onPressed: () async {
              try {
                var ventaModel =
                await VentaProvider.ventaProvider.obtenerUltimaVenta(cliente);
                if (ventaModel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este cliente no tiene ventas asociadas.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return; // No navega
                } else {
                  AppNavigator.pushNamed(AppRoutes.listadoUltimaVenta,
                      arguments: {'ventaModel': ventaModel});
                }
              } catch(e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo completar la operación: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }),
        onTap: () {
          if (widget.isForSelection) {
            AppNavigator.pop(cliente);
          } else {
            // Tu acción original
          }
        },
      ),
    );
  }
}
