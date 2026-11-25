import 'dart:developer' as developer;
import 'package:dipalza_movil/src/bloc/clientes_bloc.dart';
import 'package:dipalza_movil/src/bloc/condicion_venta_bloc.dart';
import 'package:dipalza_movil/src/model/clientes_model.dart';
import 'package:dipalza_movil/src/provider/venta_provider.dart';
import 'package:dipalza_movil/src/utils/mensaje_error.dart';
import 'package:dipalza_movil/src/services/locator.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/utils/envio_unico.dart';
import 'package:dipalza_movil/src/utils/utils.dart'; // Para colorRojoBase() y getFormatRut()
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/condicion_venta_model.dart';
import '../../model/venta_model.dart';
import '../../provider/cliente_provider.dart';
import '../../share/app.navigator.dart';
import '../../share/estado.venta.dart';
import '../../share/prefs_usuario.dart';
import '../../widget/fondo.widget.dart';

class VentaEncabezadoEdicionPage extends StatefulWidget {
  final VentaModel? ventaEnEdicion;

  const VentaEncabezadoEdicionPage({Key? key, this.ventaEnEdicion})
      : super(key: key);

  @override
  _VentaEncabezadoEdicionPageState createState() =>
      _VentaEncabezadoEdicionPageState();
}

class _VentaEncabezadoEdicionPageState
    extends State<VentaEncabezadoEdicionPage> {
  VentaModel? ventaParaEditar;
  PreferenciasUsuario pref = PreferenciasUsuario();
  final ClientesBloc _clientesBloc = ClientesBloc();
  TextEditingController? _clienteController;
  bool _estaCargando = false;
  // Grabar el encabezado espera hasta ~5 s por el GPS: sin este bloqueo un
  // segundo toque en "Detalle Venta" mandaba otro POST y creaba dos ventas.
  late final EnvioUnico _grabacion = EnvioUnico(alCambiar: (_) {
    if (mounted) setState(() {});
  });
  ClientesModel? _clienteSeleccionado;
  List<CondicionVentaModel> _listaCondicionesVenta = [];
  CondicionVentaModel? _condicionSeleccionada;
  late final DateTime _fechaFacturacion;

  /// Al modificar una venta ya creada el cliente queda fijo: solo se
  /// pueden cambiar la condición de venta y los productos. Se mira la venta
  /// con la que se abrió la página (no ventaParaEditar, que se reemplaza
  /// al guardar), así una venta nueva sigue con el cliente editable.
  bool get _esModificacion =>
      widget.ventaEnEdicion != null && widget.ventaEnEdicion!.id != -1;

  @override
  void initState() {
    super.initState();
    ventaParaEditar = widget.ventaEnEdicion;
    _cargarDatosIniciales();
    _fechaFacturacion = pref.fechaFacturacion;
  }

  /// Navega a la página completa de clientes (abierta con la lupa) y espera
  /// un resultado.
  void _navegarASeleccionCliente(BuildContext context) async {
    final cliente = await AppNavigator.pushNamed(AppRoutes.clientesSeleccion);
    // Cuando vuelve (con Navigator.of(context).pop), actualizamos el estado
    if (cliente != null && cliente is ClientesModel) {
      _actualizarClienteSeleccionado(cliente);
    }
  }

  void _actualizarClienteSeleccionado(ClientesModel cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _clienteController?.text = cliente.razon;
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter =
        DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es_ES');
    final String fechaFormateada = formatter.format(_fechaFacturacion);

    return Scaffold(
        appBar: AppBar(
          title: Text(ventaParaEditar == null || ventaParaEditar?.id == -1
              ? 'Nueva Venta'
              : 'Venta #${ventaParaEditar?.id}'),
          backgroundColor: colorRojoBase(), // Usando tu color
        ),
        body: Stack(children: <Widget>[
          const Positioned.fill(
            child: FondoWidget(),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra fina mientras cargan condiciones de venta y, al
                  // modificar, el cliente de la venta. Alto fijo: el resto
                  // de la pantalla no se mueve al aparecer o desaparecer.
                  SizedBox(
                    height: 4,
                    child: _estaCargando
                        ? const LinearProgressIndicator()
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fecha de Facturación',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black,
                        ),
                  ),
                  Text(
                    fechaFormateada,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildClienteSelector(context),
                  const SizedBox(height: 16),
                  _buildCondicionVentaModelSelector(),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: _grabacion.enCurso
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_forward),
                    label: Text(_grabacion.enCurso ? 'Grabando...' : 'Detalle Venta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorRojoBase(), // Usando tu color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: _grabacion.enCurso ||
                            (!_esModificacion && _clienteSeleccionado == null)
                        ? null // Deshabilita el botón si no hay cliente o ya está grabando
                        : () => _grabacion.ejecutar(() async {
                            try {
                              await saveVenta();
                              if (!mounted) return;
                              AppNavigator.pushNamed(AppRoutes.ventaDetalle,
                                  arguments: {
                                    'ventaModel': ventaParaEditar,
                                    'esEdicion': true
                                  });
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(mensajeParaVendedor(e, accion: 'guardar la venta')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }),
                  ),
                ],
              ),
            ),
          )
        ]));
  }

  Widget _buildClienteSelector(BuildContext context) {
    if (_esModificacion) return _buildClienteFijo();
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Autocomplete<ClientesModel>(
          initialValue: TextEditingValue(text: _clienteSeleccionado?.razon ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<ClientesModel>.empty();
            }
            return _clientesBloc.searchClientes(textEditingValue.text);
          },
          displayStringForOption: (ClientesModel option) => option.razon,
          onSelected: _actualizarClienteSeleccionado,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            _clienteController = fieldTextEditingController;
            return TextField(
              controller: _clienteController,
              focusNode: fieldFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                icon: Icon(Icons.person, color: colorRojoBase()),
                labelText: 'Cliente',
                hintText: 'Busca por nombre, código o RUT',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Ver lista completa de clientes',
                  onPressed: () => _navegarASeleccionCliente(context),
                ),
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: _clienteSeleccionado == null
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
              onChanged: (value) {
                // Si el texto deja de coincidir con el cliente ya elegido
                // (lo está editando de nuevo), se limpia la selección para
                // no guardar un cliente que ya no corresponde al texto.
                if (_clienteSeleccionado != null &&
                    value != _clienteSeleccionado!.razon) {
                  setState(() => _clienteSeleccionado = null);
                }
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<ClientesModel> onSelected,
            Iterable<ClientesModel> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ClientesModel option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: ListTile(
                          dense: true,
                          title: Text(option.razon),
                          subtitle: Text(
                              '${getFormatRut(option.rut)} · Código: ${option.codigo}'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Cliente de una venta en modificación: solo lectura.
  Widget _buildClienteFijo() {
    final venta = widget.ventaEnEdicion!;
    final nombre = _clienteSeleccionado?.razon ??
        (venta.nombreCliente.isNotEmpty ? venta.nombreCliente : 'Cargando…');
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      color: Colors.grey[200],
      child: ListTile(
        leading: Icon(Icons.person, color: colorRojoBase()),
        title: Text(nombre,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${getFormatRut(venta.rutCliente)}\nEl cliente no se puede cambiar al modificar una venta'),
        isThreeLine: true,
        trailing: const Icon(Icons.lock_outline),
      ),
    );
  }

  Widget _buildCondicionVentaModelSelector() {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<CondicionVentaModel>(
          value: _condicionSeleccionada,
          // Quita el subrayado
          decoration: const InputDecoration(
              border: InputBorder.none, labelText: 'Método de Pago'),
          isExpanded: true,
          items: _listaCondicionesVenta.map((CondicionVentaModel metodo) {
            return DropdownMenuItem<CondicionVentaModel>(
              value: metodo,
              child: Text(metodo.descripcion),
            );
          }).toList(),
          onChanged: (CondicionVentaModel? newValue) {
            setState(() {
              _condicionSeleccionada = newValue;
            });
          },
        ),
      ),
    );
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _estaCargando = true);

    // No se espera: la búsqueda de clientes solo necesita la caché lista
    // para cuando el usuario empiece a escribir, no bloquea el resto.
    _clientesBloc.ensureFresh();

    try {
      _listaCondicionesVenta =
          await locator<CondicionVentaBloc>().ensureFresh();
      if (!mounted) return;
      if (ventaParaEditar != null) {
        _cargarDatosParaEdicion();
      } else {
        if (_listaCondicionesVenta.isNotEmpty) {
          _condicionSeleccionada = _listaCondicionesVenta.first;
        }
      }
    } catch (e) {
      developer.log('Error al cargar datos iniciales', name: 'VentaEncabezadoEdicion', error: e);
      // (Aquí deberías mostrar un snackbar o alerta de error)
    }

    if (!mounted) return;
    setState(() => _estaCargando = false);
  }

  void _cargarDatosParaEdicion() async {
    setState(() => _estaCargando = true);

    final venta = ventaParaEditar!;

    try {
      final cliente = await ClientesProvider.clientesProvider
          .obtenerClienteByRutCodigo(venta.rutCliente, venta.codigoCliente);

      final condicion = _listaCondicionesVenta.firstWhere(
          (c) => c.codigo == venta.codigoCondicionVenta,
          orElse: () => _listaCondicionesVenta.first);
      if (!mounted) return;
      setState(() {
        _clienteSeleccionado = cliente;
        _clienteController?.text = cliente.razon;
        _condicionSeleccionada = condicion;
        _estaCargando = false;
      });
    } catch (e) {
      developer.log('Error al cargar datos para edición', name: 'VentaEncabezadoEdicion', error: e);
      if (!mounted) return;
      setState(() => _estaCargando = false);
    }
  }

  Future<VentaModel> saveVenta() async {
    // En modificación el cliente (y su ruta) se toman de la venta original,
    // nunca de la selección: así no hay forma de cambiarlo, y tampoco
    // depende de que la búsqueda del cliente haya respondido.
    final original = widget.ventaEnEdicion;
    final rutCliente =
        _esModificacion ? original!.rutCliente : _clienteSeleccionado!.rut;
    final codigoCliente =
        _esModificacion ? original!.codigoCliente : _clienteSeleccionado!.codigo;
    final codigoRuta =
        _esModificacion ? original!.codigoRuta : _clienteSeleccionado!.ruta;
    VentaModel ventaModel = VentaModel(
        id: ventaParaEditar?.id ?? -1,
        fecha: _fechaFacturacion,
        rutCliente: rutCliente,
        codigoCliente: codigoCliente,
        codigoVendedor: pref.vendedor,
        tipoVendedor: pref.tipo,
        codigoRuta: codigoRuta,
        codigoCondicionVenta: _condicionSeleccionada!.codigo,
        detalles: ventaParaEditar?.detalles ?? [],
        // Preserva el estado real de la venta que se está editando (nunca
        // hardcodear OPENED acá): mandar OPENED a ciegas revertía ventas ya
        // CLOSED/facturadas de vuelta a editable en el server, sin tocar la
        // factura ya emitida -- una venta nueva sí arranca en OPENED
        // (ventaParaEditar es null en ese caso).
        estadoVenta: ventaParaEditar?.estadoVenta ?? EstadoVenta.OPENED);

    final VentaModel ventaGuardada =
        await VentaProvider.ventaProvider.saveVentaEncabezado(ventaModel);
    if (mounted) setState(() {
      ventaParaEditar = ventaGuardada;
    });
    return ventaGuardada;
  }
}
