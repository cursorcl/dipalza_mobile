// import 'package:dipalza_movil/src/bloc/productos_bloc.dart';
import 'package:dipalza_movil/src/bloc/productos_bloc.dart';
import 'package:dipalza_movil/src/model/producto_model.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:dipalza_movil/src/widget/fondo.widget.dart';
import 'package:flutter/material.dart';

import '../../share/app.navigator.dart';
import '../../share/app_scaffold_key.dart';
import '../../widget/connectivity_banner.widget.dart';

class ProductosPage extends StatefulWidget {
  final bool isForSelection;

  const ProductosPage({Key? key, this.isForSelection = false})
      : super(key: key);

  @override
  _ProductosPageState createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final ProductsBloc _productsBloc = new ProductsBloc();
  TextEditingController controller = new TextEditingController();
  final List<ProductosModel> _searchResult = [];
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _productsBloc.ensureFresh();
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
        backgroundColor: colorRojoBase(),
        title: Container(
          child: const Center(
            child: Text(
              'Productos',
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
                _showSearch = true;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: FondoWidget(),
          ),
          Positioned.fill(
            child: Column(
              children: <Widget>[
                // ¡Aquí está! Se mostrará en la parte superior de la pantalla.
                const ConnectivityBanner(),
                // El input de búsqueda (se mostrará o no)
                _showSearch ? _creaInputBuscar(context) : Container(),
                Expanded(
                  // 1. EL STREAMBUILDER ES EL WIDGET PRINCIPAL
                  child: StreamBuilder<List<ProductosModel>>(
                    stream: _productsBloc.productsStream,
                    builder: (context, snapshot) {
                      // 2. MANEJO DE ESTADOS DEL STREAM
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No existen Productos a mostrar.'));
                      }

                      // 3. LA LISTA COMPLETA VIENE DIRECTAMENTE DEL STREAM
                      final listaCompleta = snapshot.data!;

                      // 4. LA LÓGICA DE BÚSQUEDA AHORA USA LA LISTA DEL STREAM
                      final listaAMostrar = _filtrarLista(listaCompleta);

                      return _creaListaProductos(context, listaAMostrar);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ProductosModel> _filtrarLista(List<ProductosModel> listaCompleta) {
    if (controller.text.isEmpty) {
      return listaCompleta;
    } else {
      _searchResult.clear();
      listaCompleta.forEach((producto) {
        if (producto.descripcion
                .toUpperCase()
                .contains(controller.text.toUpperCase()) ||
            producto.articulo.toUpperCase() ==
                controller.text.toUpperCase()) {
          _searchResult.add(producto);
        }
      });
      return _searchResult;
    }
  }

  Widget _creaInputBuscar(BuildContext context) {
    return AnimatedOpacity(
      opacity: _showSearch ? 1.0 : 0.0,
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
                    _showSearch = false;
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

  Widget _creaListaProductos(
      BuildContext context, List<ProductosModel> listaProducto) {
    if (listaProducto.length == 0) {
      return const Center(
        child: Text('No existen Productos a mostrar.'),
      );
    }

    return RefreshIndicator(
      onRefresh: getListaProductosRefrescar,
      child: ListView.builder(
        itemCount: listaProducto.length,
        itemBuilder: (context, i) {
          return _creaCard(listaProducto[i]);
        },
      ),
    );
  }

  _creaCard(ProductosModel producto) {
    final stock = producto.stock > 0 ? producto.stock : 0;
    return Card(
      child: ListTile(
          leading: CircleAvatar(
            radius: 20,
            child: const Icon(Icons.card_giftcard),
            backgroundColor: colorRojoBase(),
            foregroundColor: Colors.white,
          ),
          title: Text(
            producto.descripcion,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
              color: Colors.black,
            ),
          ),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Precio:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '\$${producto.ventaneto.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Stock:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${stock.toStringAsFixed(2)} ${producto.unidad}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: stock > 0 ? Colors.blueAccent : Colors.red,
                    ),
                  ),
                ],
              ),
              if (producto.numbered)
                Row(
                  children: [
                    const Text(
                      'Piezas:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${producto.pieces.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: producto.pieces > 0
                            ? Colors.blueAccent
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          onTap: () {
            if (widget.isForSelection) {
              AppNavigator.pop(producto);
            } else {
              // Tu acción original
            }
          }),
    );
  }

  Future<void> getListaProductosRefrescar() async {
    // Solo le decimos al BLoC que recargue. El StreamBuilder se encargará del resto.
    await _productsBloc.forceRefresh();
  }
}
