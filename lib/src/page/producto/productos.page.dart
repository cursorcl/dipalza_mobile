// import 'package:dipalza_movil/src/bloc/productos_bloc.dart';
import 'package:dipalza_movil/src/bloc/productos_bloc.dart';
import 'package:dipalza_movil/src/model/producto_model.dart';
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:dipalza_movil/src/widget/fondo.widget.dart';
import 'package:flutter/material.dart';

import '../../share/app.navigator.dart';
import '../../share/app_scaffold_key.dart';
import '../../share/teclado.busqueda.producto.dart';
import '../../share/app.formatter.dart';
import '../../widget/connectivity_banner.widget.dart';
import '../../widget/lista.widgets.dart';

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
  bool _seleccionado = false;

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
                        return RefreshIndicator(
                          onRefresh: getListaProductosRefrescar,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              EstadoVacioLista(
                                icono: Icons.inventory_2_outlined,
                                titulo: 'No hay productos para mostrar',
                                mensaje:
                                    'Desliza hacia abajo para volver a cargarlos.',
                              ),
                            ],
                          ),
                        );
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
                keyboardType: tecladoBusquedaProducto,
                autocorrect: false,
                enableSuggestions: false,
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
      // Solo llega vacía por la búsqueda: sin productos se corta antes.
      return ListView(
        children: [
          EstadoVacioLista(
            icono: Icons.search_off,
            titulo:
                'No hay productos que coincidan con "${controller.text.trim()}"',
            textoAccion: 'Limpiar búsqueda',
            accionPrincipal: false,
            onAccion: () => setState(() => controller.clear()),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: getListaProductosRefrescar,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: listaProducto.length,
        itemBuilder: (context, i) {
          return _creaCard(listaProducto[i]);
        },
      ),
    );
  }

  /// Devuelve el producto elegido. Un segundo toque mientras la página se
  /// cierra se ignora: si no, cerraba también la pantalla de abajo.
  void _seleccionar(ProductosModel producto) {
    // Si esta lista ya no es la pantalla de arriba (se está cerrando con
    // "atrás"), cerrar "la de arriba" cerraría la del ítem y le devolvería un
    // producto donde se espera una venta (crash en la v2.20.1).
    if (_seleccionado || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _seleccionado = true;
    AppNavigator.pop(producto);
  }

  Widget _creaCard(ProductosModel producto) {
    final stock = producto.stock > 0 ? producto.stock : 0.0;
    final estiloSecundario =
        TextStyle(fontSize: 14, color: Colors.grey.shade700);
    // Precio en formato chileno, como en el resto de la app ("$1.234").
    // Si el precio trae decimales se muestran, para no redondear a escondidas.
    final decimales = producto.ventaneto % 1 == 0 ? 0 : 2;
    return TarjetaLista(
      padding: const EdgeInsets.all(12),
      onTap: widget.isForSelection ? () => _seleccionar(producto) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(producto.descripcion.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('Cód. ${producto.articulo.trim()} · ${producto.unidad}',
              style: estiloSecundario),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Expanded (no Flexible + Spacer): el texto de stock ocupa todo
              // el espacio libre y el precio queda pegado a la derecha en
              // todas las filas, igual que cuando va la cápsula.
              if (stock > 0)
                Expanded(
                  child: Text(
                      'Stock ${AppFormatters.formatoCantidad.format(stock)}'
                      '${producto.numbered ? ' · ${producto.pieces.toStringAsFixed(0)} pz' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estiloSecundario),
                )
              else ...[
                const Capsula(
                    texto: 'Sin stock',
                    color: Colors.red,
                    icono: Icons.block),
                const Spacer(),
              ],
              const SizedBox(width: 8),
              Text(getValorModena(producto.ventaneto, decimales),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(width: 4),
              Text('neto',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> getListaProductosRefrescar() async {
    // Solo le decimos al BLoC que recargue. El StreamBuilder se encargará del resto.
    await _productsBloc.forceRefresh();
  }
}
