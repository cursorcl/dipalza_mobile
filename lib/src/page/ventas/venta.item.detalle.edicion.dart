import 'dart:developer' as developer;

import 'package:dipalza_movil/src/model/venta_model.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:dipalza_movil/src/utils/alert_util.dart';
import 'package:flutter/material.dart';

import '../../bloc/productos_bloc.dart';
import '../../model/producto_model.dart';
import '../../model/venta_detalle_model.dart';
import '../../provider/productos_provider.dart';
import '../../share/app.navigator.dart';

class VentaEdicionItemDetalle extends StatefulWidget {
  final VentaModel? actualVenta;
  final VentaDetalleModel? actualVentaDetalle; // si viene nulo, es nuevo

  const VentaEdicionItemDetalle(
      {Key? key, this.actualVenta, this.actualVentaDetalle})
      : super(key: key);

  @override
  _VentaEdicionItemDetalleState createState() =>
      _VentaEdicionItemDetalleState();
}

class _VentaEdicionItemDetalleState extends State<VentaEdicionItemDetalle> {
  final ProductosProvider _productosProvider =
      ProductosProvider.productosProvider;
  final ProductsBloc _productosBloc = ProductsBloc();

  late TextEditingController _productoController;
  late TextEditingController _cantidadController;
  late TextEditingController _descuentoController;

  late FocusNode _productoFocusNode;
  late FocusNode _cantidadFocusNode;
  late FocusNode _descuentoFocusNode;
  late FocusNode _guardarFocusNode;

  ProductosModel? productoEnVenta = null;

  bool _isBlocReady = false;

  String? _productoId;
  double _precioUnitario = 0;
  double _valorFinal = 0;
  double _pesoTotal = 0;
  bool _esNumerado = false;
  double _stockDisponible = 0;
  double _pesoPromedio = 0;
  double _valorDescuento = 0;
  String _unidadProducto = 'un';
  double _porcentajeILA = 0;
  double _porcentajeIVA = 0;
  bool _estaCargandoStock = false;
  int _listaPrecio = 1;
  double _precioLista1 = 0;
  double _precioLista2 = 0;

  // Se utiliza para colocar rojo el borde del campo cantidad si excede el stock
  bool _excedeStock = false;

  @override
  void initState() {
    super.initState();
    _setupPagina();
  }

  Future<void> _setupPagina() async {
    await _productosBloc.initialLoadDone;

    final pref = PreferenciasUsuario();
    final d = widget.actualVentaDetalle;

    _productoFocusNode = FocusNode();
    _cantidadFocusNode = FocusNode();
    _descuentoFocusNode = FocusNode();
    _guardarFocusNode = FocusNode();

    _cantidadController =
        TextEditingController(text: d?.cantidad.toString() ?? '0');
    _descuentoController = TextEditingController(
        text: d?.porcentajeDescuento.toString() ?? '0'); // '0' por defecto

    if (d != null) {
      final String claveBusqueda = d.idProducto;
      productoEnVenta = _productosBloc.searchProduct(claveBusqueda);
      if (productoEnVenta != null) {
        _productoId = productoEnVenta!.articulo;
        _productoController =
            TextEditingController(text: productoEnVenta!.descripcion);
        _precioLista1 = productoEnVenta!.ventaneto;
        _precioLista2 = productoEnVenta!.precioLista2;
        if (_precioLista2 > 0) {
          final diffL1 = (d.precioUnitario - _precioLista1).abs();
          final diffL2 = (d.precioUnitario - _precioLista2).abs();
          _listaPrecio = diffL2 < diffL1 ? 2 : 1;
        }
        _precioUnitario = _listaPrecio == 1 ? _precioLista1 : _precioLista2;
        _esNumerado = productoEnVenta!.numbered;
        _unidadProducto = productoEnVenta!.unidad;
        _porcentajeILA = productoEnVenta!.porcila;
        if (_esNumerado) {
          _cantidadController.text = d.piezas.toString();
        }
        _cargarStockProducto(productoEnVenta!.articulo);
      } else {
        _productoController = TextEditingController(text: d.nombreProducto);
        _precioUnitario = d.precioUnitario;
        _esNumerado = d.piezas > 0;
      }
      _porcentajeIVA = d.porcentajeIva;
    } else {
      productoEnVenta = null;
      _productoController = TextEditingController(text: '');
      _porcentajeIVA = pref.iva;
    }
    _addSelectAllListener(_productoFocusNode, _productoController);
    _addSelectAllListener(_cantidadFocusNode, _cantidadController);
    _addSelectAllListener(_descuentoFocusNode, _descuentoController);

    _recalcularTotal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.actualVentaDetalle == null)
        FocusScope.of(context).requestFocus(_productoFocusNode);
      else
        FocusScope.of(context).requestFocus(_cantidadFocusNode);
    });
    setState(() {
      _isBlocReady = true;
    });
  }

  void _addSelectAllListener(FocusNode node, TextEditingController controller) {
    node.addListener(() {
      if (node.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _descuentoController.dispose();
    _cantidadFocusNode.dispose();
    _descuentoFocusNode.dispose();
    _guardarFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBlocReady) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.actualVentaDetalle == null ? 'Agregar producto' : 'Editar detalle'),
          backgroundColor: Colors.redAccent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool enabled = _productoController.text.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.actualVentaDetalle == null ? 'Agregar producto' : 'Editar detalle'),
        backgroundColor: Colors.redAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: TextButton.icon(
              onPressed: enabled ? _guardar : null,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text('Guardar'),
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

      // ✅ ListView evita RenderFlex overflow con teclado abierto
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 7),
          children: [
            // =========================
            // PRODUCTO (Autocomplete ORIGINAL)
            // =========================
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: (widget.actualVentaDetalle == null)
                  ? Autocomplete<ProductosModel>(
                initialValue: TextEditingValue(text: _productoController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<ProductosModel>.empty();
                  }
                  return _productosBloc.searchProducts(textEditingValue.text);
                },
                displayStringForOption: (ProductosModel option) => option.descripcion,
                onSelected: (ProductosModel seleccion) {
                  _actualizarProductoSeleccionado(seleccion);
                  _cargarStockProducto(seleccion.articulo);
                },
                fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                    ) {
                  // Mantener sincronizado con tus campos
                  _productoController = fieldTextEditingController;
                  _productoFocusNode = fieldFocusNode;
                  _addSelectAllListener(_productoFocusNode, _productoController);

                  return TextField(
                    controller: _productoController,
                    focusNode: _productoFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar por Código o Nombre',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.manage_search),
                        tooltip: 'Buscar en lista completa',
                        onPressed: _buscarProducto,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (term) => _buscarProductoPorTermino(term),
                  );
                },
                optionsViewBuilder: (
                    BuildContext context,
                    AutocompleteOnSelected<ProductosModel> onSelected,
                    Iterable<ProductosModel> options,
                    ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ProductosModel option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: ListTile(
                                dense: true,
                                title: Text(option.descripcion),
                                subtitle: Text('Código: ${option.articulo}'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              )
                  : TextField(
                controller: _productoController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  isDense: true,
                ),
              ),
            ),

            // =========================
            // SELECTOR LISTA DE PRECIO (AÑADIDO)
            // =========================
            _buildSelectorPrecio(),

            // =========================
            // CANTIDAD (sin +/-)
            // =========================
            TextField(
              controller: _cantidadController,
              focusNode: _cantidadFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _excedeStock ? Colors.red : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _excedeStock ? Colors.red : Colors.black12),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _excedeStock ? Colors.red : Colors.redAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) {
                // Mantener tu lógica existente
                final cantidad = double.tryParse(_cantidadController.text.replaceAll(',', '.')) ?? 0;
                setState(() =>
                _excedeStock = cantidad > _stockDisponible);
                _recalcularTotal();
              },
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_descuentoFocusNode),
            ),

            if (_esNumerado) ...[
              const SizedBox(height: 6),
              Text(
                'Peso total: ${_pesoTotal.toStringAsFixed(2)} kg',
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 14),

            // =========================
            // DESCUENTO (sin +/-)
            // =========================
            TextField(
              controller: _descuentoController,
              focusNode: _descuentoFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Descuento (%)',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.redAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => _recalcularTotal(),
              onSubmitted: (_) => _descuentoFocusNode.unfocus(),
            ),

            const SizedBox(height: 14),

            // =========================
            // RESUMEN
            // =========================
            _buildResumenInferior(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildResumenInferior() {
    String formatCurrency(double value) => '\$${value.toStringAsFixed(0)}';
    String formatNumber(double value) => value.toStringAsFixed(2);

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            _buildResumenRow(
              'Stock:',
              _estaCargandoStock
                  ? 'Cargando...'
                  : '${formatNumber(_stockDisponible)} ($_unidadProducto)',
              valueColor: _stockDisponible > 0 ? Colors.blueAccent : Colors.red,
              fontSize: 13,
            ),
            _buildResumenRow(
              'Precio Unitario:',
              formatCurrency(_precioUnitario),
              fontSize: 13,
            ),
            _buildResumenRow(
              'Descuento:',
              formatCurrency(_valorDescuento),
              fontSize: 13,
              valueColor:
              _valorDescuento > 0 ? Colors.orange[700]! : Colors.grey[700]!,
            ),
            const Divider(height: 12, thickness: 0.8),
            _buildResumenRow(
              'Total Item:',
              formatCurrency(_valorFinal),
              valueColor: Colors.green[700]!,
              isBold: true,
              fontSize: 16,
            ),
            const Divider(height: 12, thickness: 0.8),
            _buildResumenRow(
              'ILA ${formatNumber(_porcentajeILA)}%:',
              formatCurrency(_valorFinal * _porcentajeILA / 100),
              fontSize: 13,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value,
      {Color valueColor = Colors.black,
        bool isBold = false,
        double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

// AÑADIDO: Widget para seleccionar la lista de precios.
  Widget _buildSelectorPrecio() {
    // Solo muestra el selector si hay un producto cargado.
    if (productoEnVenta == null) {
      return const SizedBox.shrink(); // No muestra nada si no hay producto
    }

    // Función para formatear el precio y que se vea bien
    String formatPrice(double price) => '\$${price.toStringAsFixed(0)}';

    // Si _precioLista2 es nulo o negativo, lo tratamos como 0.
    final precio2 = _precioLista2 > 0 ? _precioLista2 : 0.0;
    final bool precio2Habilitado = precio2 > 0;

    // Sin lista Secundaria activa no hay nada entre qué elegir: se oculta el
    // selector completo y se deja solo el precio único (ya visible en el
    // resumen más abajo, formatCurrency(_precioUnitario)).
    if (!precio2Habilitado) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escoja Precio',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),

          // MODIFICADO: control propio de dos segmentos para poder darle a
          // cada uno su propio color de fondo a todo lo ancho (SegmentedButton
          // solo permite un único color de "seleccionado" compartido).
          Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: _buildPrecioSegmento(
                    titulo: 'Precio 1',
                    precio: formatPrice(_precioLista1),
                    seleccionado: _listaPrecio == 1,
                    habilitado: true,
                    colorFondo: Colors.red[100]!,
                    colorTexto: Colors.red[900]!,
                    colorFondoSeleccionado: Colors.redAccent,
                    colorTextoSeleccionado: Colors.white,
                    onTap: () => _seleccionarListaPrecio(1),
                  ),
                ),
                Container(width: 1, color: Colors.black26),
                Expanded(
                  child: _buildPrecioSegmento(
                    titulo: 'Precio 2',
                    precio: formatPrice(precio2),
                    seleccionado: _listaPrecio == 2,
                    habilitado: precio2Habilitado,
                    colorFondo: Colors.green[200]!,
                    colorTexto: Colors.green[900]!,
                    colorFondoSeleccionado: Colors.green[500]!,
                    colorTextoSeleccionado: Colors.white,
                    onTap: precio2Habilitado
                        ? () => _seleccionarListaPrecio(2)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // AÑADIDO: segmento individual del selector de precio, con fondo a todo
  // lo ancho igual al del segmento "Precio 1" (antes solo un chip pequeño).
  Widget _buildPrecioSegmento({
    required String titulo,
    required String precio,
    required bool seleccionado,
    required bool habilitado,
    required Color colorFondo,
    required Color colorTexto,
    required Color colorFondoSeleccionado,
    required Color colorTextoSeleccionado,
    required VoidCallback? onTap,
  }) {
    final Color fondo = !habilitado
        ? Colors.grey.withOpacity(0.1)
        : (seleccionado ? colorFondoSeleccionado : colorFondo);
    final Color texto = !habilitado
        ? Colors.grey
        : (seleccionado ? colorTextoSeleccionado : colorTexto);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: fondo,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (seleccionado) ...[
                  Icon(Icons.check, size: 14, color: texto),
                  const SizedBox(width: 4),
                ],
                Text(
                  titulo,
                  style: TextStyle(color: texto, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              precio,
              style: TextStyle(color: texto, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _seleccionarListaPrecio(int lista) {
    setState(() {
      _listaPrecio = lista;
      _precioUnitario = _listaPrecio == 1 ? _precioLista1 : _precioLista2;
    });
    _recalcularTotal();
  }
  void _buscarProducto() async {
    productoEnVenta = await AppNavigator.pushNamed<ProductosModel?>(
        AppRoutes.productosSeleccion);
    if (productoEnVenta != null && productoEnVenta is ProductosModel) {
      _actualizarProductoSeleccionado(productoEnVenta);
      _cargarStockProducto(productoEnVenta!.articulo);
    }
  }

  Future<void> _cargarStockProducto(String codigo) async {
    setState(() => _estaCargandoStock = true);
    try {
      productoEnVenta = await _productosProvider.obtenerProducto(codigo);

      if (productoEnVenta != null) {
        _productosBloc.updatePorduct(productoEnVenta!);
        _esNumerado = productoEnVenta!.numbered;
        _precioLista1 = productoEnVenta!.ventaneto;
        _precioLista2 = productoEnVenta!.precioLista2;
        _precioUnitario = _listaPrecio == 1 ? _precioLista1 : _precioLista2;
        if (_esNumerado) {
          _pesoPromedio = await _productosProvider.obtenerPesoPromedioProducto(codigo);
        }
        setState(() {
          if (_esNumerado) {
            _stockDisponible =
                productoEnVenta!.pieces - productoEnVenta!.piezasVentas;
          } else {
            _stockDisponible =
                productoEnVenta!.stock - productoEnVenta!.stockVentas;
          }
          _unidadProducto = productoEnVenta!.unidad;
          _porcentajeILA = productoEnVenta!.porcila;
        });
      }
    } catch (e) {
      _mostrarError('Error al cargar stock: $e');
      setState(() => _stockDisponible = 0);
    } finally {
      setState(() => _estaCargandoStock = false);
    }
  }

  void _buscarProductoPorTermino(String termino) async {
    if (termino.isEmpty) return;

    final productoEncontrado = _productosBloc.searchProduct(termino);

    if (productoEncontrado != null) {
      _actualizarProductoSeleccionado(productoEncontrado);
      _cargarStockProducto(productoEncontrado.articulo);
    } else {
      _mostrarError('Producto no encontrado: $termino');
    }
  }

  void _actualizarProductoSeleccionado(dynamic producto) {
    setState(() {
      _productoId = producto.articulo;
      _productoController.text = producto.descripcion;
      _precioLista1 = producto.ventaneto;
      _precioLista2 = producto.precioLista2;

      // MODIFICADO: Siempre reiniciamos a la Lista 1 por defecto.
      _listaPrecio = 1;
      // MODIFICADO: El precio unitario por defecto es el de la lista 1.
      _precioUnitario = _precioLista1;

      _esNumerado = producto.numbered;
      _pesoTotal = 0;

      _unidadProducto = producto.unidad;
      _porcentajeILA = producto.porcila;
      _stockDisponible = 0; // Se resetea
      _estaCargandoStock = true; // Se pone a cargar
      // al cambiar el código de producto se debe limpiar la lista de piezas asociadas que tiene el registro.
      _recalcularTotal();
      FocusScope.of(context).requestFocus(_cantidadFocusNode);
    });
  }

  /// Recalcula el valor del descuento y el total final
  void _recalcularTotal() {
    final cantidad = double.tryParse(_cantidadController.text) ?? 0;
    final porcentajeDescuento = double.tryParse(_descuentoController.text) ?? 0;
    final subtotal = cantidad * _precioUnitario;
    final descuentoMonto = subtotal * (porcentajeDescuento / 100);
    final total = subtotal - descuentoMonto;

    setState(() {
      _pesoTotal = _pesoPromedio * cantidad;
      _valorFinal = total;
      _valorDescuento = descuentoMonto;
    });
  }

  void _guardar() async {
    var cantidad = double.tryParse(_cantidadController.text) ?? 0;
    final porcentajeDescuento = double.tryParse(_descuentoController.text) ?? 0;

    if (_productoId == null) {
      _mostrarError('Debes seleccionar un producto.');
      return;
    }
    if (cantidad <= 0) {
      _mostrarError('La cantidad debe ser mayor a cero.');
      return;
    }

    if (porcentajeDescuento < 0 || porcentajeDescuento > 50) { // MODIFICADO: El descuento máximo debe ser menor a 100
      _mostrarError('El descuento debe estar entre 0 y 50%.');
      return;
    }
    try {
      final codigoProducto = _productoId!;
      final producto = await _productosProvider.obtenerProducto(codigoProducto);
      if (producto == null) {
        _mostrarError('Error: No se pudo validar el producto.');
        return;
      }

      _porcentajeILA = producto.porcila;
      final unidad = producto.unidad;

      // MODIFICADO: Se usa el _precioUnitario del estado, que respeta la selección del usuario.
      // Se elimina el recálculo redundante.
      final subtotal = (_esNumerado ? _pesoTotal : cantidad) * _precioUnitario;
      final totalDescuento = subtotal * (porcentajeDescuento / 100);
      final total = subtotal - totalDescuento;

      _productosBloc.updatePorduct(producto);

      var stockReal = productoEnVenta!.stock - productoEnVenta!.stockVentas;
      if (_esNumerado) {
        stockReal = productoEnVenta!.pieces - productoEnVenta!.piezasVentas;
      }
      setState(() => _stockDisponible = stockReal);
      final ventaId = widget.actualVenta == null ? -1 : widget.actualVenta!.id;

      final porcIva = _porcentajeIVA; // Usamos el IVA del estado
      final totalIva = total * porcIva / 100;
      final porcIla = producto.porcila;
      final totalIla = total * porcIla / 100;

      var piezas = 0;
      if (_esNumerado) {
        piezas = cantidad.toInt();
        cantidad = cantidad * _pesoPromedio;
      }

      final detalle = VentaDetalleModel(
          id: widget.actualVentaDetalle == null
              ? -1
              : widget.actualVentaDetalle!.id,
          ventaId: ventaId,
          idProducto: producto.articulo,
          nombreProducto: producto.descripcion,
          cantidad: cantidad,
          // MODIFICADO: Se guarda el precio que el usuario realmente seleccionó.
          precioUnitario: _precioUnitario,
          porcentajeDescuento: porcentajeDescuento,
          porcentajeIva: _porcentajeIVA,
          porcentajeIla: _porcentajeILA,
          totalDescuento: totalDescuento,
          totalIva: totalIva,
          totalIla: totalIla,
          totalLinea: total,
          unidad: unidad,
          piezas: piezas,
          piezasDetalle: []);
      String json = ventaDetalleModelToJson(detalle);
      developer.log("Enviando a grabar detalle venta $json");
      final VentaModel ventaModel =
      await VentaProvider.ventaProvider.saveItemVenta(detalle);
      AppNavigator.pop(ventaModel);
    } catch (e, s) {
      showAlertDialog(context, s.toString(), Icons.error);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }
}