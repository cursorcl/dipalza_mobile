// ignore_for_file: unused_field, unused_element

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../model/rutas_model.dart';
import '../../provider/vendedor_ruta_provider.dart';
import '../../services/api_client.dart';
import '../../services/background_location_service.dart';
import '../../share/app.navigator.dart';
import '../../share/app_routes.dart';
import '../../share/app_scaffold_key.dart';
import '../../share/prefs_usuario.dart';
import '../../utils/jwt_util.dart';
import '../../utils/utils.dart';
import '../../widget/connectivity_banner.widget.dart';
import 'widgets/servidor_config_fields.dart';

enum ConnectionStatus { unknown, ok, invalid }

class ConfiguracionPage extends StatefulWidget {
  final bool showMenuIcon;
  const ConfiguracionPage({super.key, this.showMenuIcon = false});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final _prefs = PreferenciasUsuario();
  late TextEditingController _hostController;
  late TextEditingController _puertoController;
  List<RutasModel> _rutasAsignadas = [];
  DateTime? _fechaTrabajo;
  double? _iva;
  double? _ila;
  late final NumberFormat _pct = NumberFormat.decimalPattern('es_CL');

  ConnectionStatus _status = ConnectionStatus.unknown;
  bool _probando = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: _prefs.servidorHost);
    _puertoController = TextEditingController(text: _prefs.servidorPuerto);
    // Estado inicial: si hay URL, no asumimos conectividad hasta probar
    _status = ConnectionStatus.unknown;
    _cargarRutasAsignadas();
  }

  Future<void> _cargarRutasAsignadas() async {
    try {
      final rutas = await VendedorRutaProvider()
          .obtenerRutasAsignadas(_prefs.vendedor, _prefs.tipo);
      if (!mounted) return;
      setState(() => _rutasAsignadas = rutas);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudieron cargar las rutas asignadas')));
    }
  }

  bool get _canShowLogout {
    if (_prefs.access_token.isEmpty) return false;
    // Elige UNA de las dos líneas según tu tipo de token:
    return !isJwtExpired(_prefs.access_token); // JWT
  }

  @override
  void dispose() {
    _hostController.dispose();
    _puertoController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _pickFechaTrabajo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaTrabajo ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Seleccione fecha de trabajo',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) {
      setState(() => _fechaTrabajo = picked);
      _prefs.fechaFacturacion = picked; // mismo setter que usa LoginPage
    }
  }

  Future<void> _pickRutas() async {
    final seleccion = await AppNavigator.pushNamed(
      AppRoutes.rutas,
      arguments: {'multiSelect': true, 'seleccionInicial': _rutasAsignadas},
    );
    if (seleccion != null) {
      final nuevas = List<RutasModel>.from(seleccion);
      setState(() => _rutasAsignadas = nuevas);
      _prefs.rutasAsignadas = nuevas.map((r) => r.codigo).toList();
      try {
        await VendedorRutaProvider().guardarRutasAsignadas(
            _prefs.vendedor, _prefs.tipo, _prefs.rutasAsignadas);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo guardar la selección de rutas, intente nuevamente')));
      }
    }
  }

  // ---------- Prueba de conexión (HEAD/GET /health o raíz) ----------

  Future<bool> _pingServer(String baseUrl,
      {Duration timeout = const Duration(seconds: 4)}) async {
    final uri = Uri.parse(baseUrl);

    final u = uri.replace(path: '/ping');

    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final request = await client.getUrl(u).timeout(timeout);
      request.headers.set(HttpHeaders.userAgentHeader, 'DipalzaApp/1.0');
      final response = await request.close().timeout(timeout);
      // Códigos 2xx o 3xx consideramos OK
      if (response.statusCode >= 200 && response.statusCode < 400) {
        client.close(force: true);
        return true;
      }
      client.close(force: true);
    } catch (_) {
      // probar siguiente candidato
    }
    return false;
  }

  String _fmtPct(double v) => '${_pct.format(v)} %';

// Acepta “19”, “19.0” o “19,0” y valida rango 0..100
  String? _validatePct(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return 'Ingrese un valor';
    final val = double.tryParse(t.replaceAll('.', '').replaceAll(',', '.')) ??
        double.tryParse(t);
    if (val == null) return 'Número inválido';
    if (val < 0 || val > 100) return 'Debe estar entre 0 y 100';
    return null;
  }

  double _parsePct(String raw) {
    // ya validado
    return double.parse(raw.trim().replaceAll('.', '').replaceAll(',', '.'));
  }

  Future<void> _editTax({
    required String titulo,
    required double valorActual,
    required ValueChanged<double> onSave,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: _pct.format(valorActual));
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Ej.: 19 o 19,0',
                    suffixText: '%',
                  ),
                  validator: _validatePct,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final v = _parsePct(controller.text);
                          onSave(v);
                          AppNavigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '$titulo actualizado a ${_fmtPct(v)}')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ---------- UI helpers ----------

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (_status) {
      case ConnectionStatus.ok:
        return Colors.green;
      case ConnectionStatus.invalid:
        return Colors.red;
      case ConnectionStatus.unknown:
      default:
        return cs.tertiary; // ámbar/neutral según tema
    }
  }

  IconData _statusIcon() {
    switch (_status) {
      case ConnectionStatus.ok:
        return Icons.check_circle;
      case ConnectionStatus.invalid:
        return Icons.cancel;
      case ConnectionStatus.unknown:
      default:
        return Icons.help;
    }
  }

  String _statusText() {
    switch (_status) {
      case ConnectionStatus.ok:
        return 'Conectado';
      case ConnectionStatus.invalid:
        return 'No disponible';
      case ConnectionStatus.unknown:
      default:
        return 'No verificado';
    }
  }

  Future<void> _copiar() async {
    final text = _prefs.urlBase;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Dirección copiada')));
  }

  // ---------- Bottom sheet edición ----------

  Future<void> _openEditServerSheet() async {
    final formKey = GlobalKey<FormState>();
    _hostController.text = _prefs.servidorHost;
    _puertoController.text = _prefs.servidorPuerto;
    bool sheetIsHttps = _prefs.servidorEsquema != 'http';

    String candidatoUrlBase() {
      final host = _hostController.text.trim();
      final puerto = _puertoController.text.trim();
      final esquema = sheetIsHttps ? 'https' : 'http';
      return puerto.isEmpty ? '$esquema://$host' : '$esquema://$host:$puerto';
    }

    void aplicarRecienteAloscampos(String urlBase) {
      final uri = Uri.tryParse(urlBase);
      if (uri == null || uri.host.isEmpty) return;
      _hostController.text = uri.host;
      _puertoController.text = uri.hasPort ? '${uri.port}' : '';
      sheetIsHttps = uri.scheme != 'http';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: viewInsets.bottom + 16,
              top: 8,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dirección del servidor',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ServidorConfigFields(
                    hostController: _hostController,
                    puertoController: _puertoController,
                    isHttps: sheetIsHttps,
                    onEsquemaChanged: (value) =>
                        setModalState(() => sheetIsHttps = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _probando
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  setState(() => _probando = true);
                                  final ok =
                                      await _pingServer(candidatoUrlBase());
                                  if (!mounted) return;
                                  setState(() {
                                    _probando = false;
                                    _status = ok
                                        ? ConnectionStatus.ok
                                        : ConnectionStatus.invalid;
                                  });
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content: Text(ok
                                              ? 'Conexión verificada'
                                              : 'No se pudo conectar')));
                                },
                          icon: _probando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: const Text('Probar conexión'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          _prefs.servidorHost = _hostController.text.trim();
                          _prefs.servidorPuerto =
                              _puertoController.text.trim();
                          _prefs.servidorEsquema =
                              sheetIsHttps ? 'https' : 'http';
                          ApiClient().dio.options.baseUrl = _prefs.urlBase;
                          _prefs.recentEndpoints = <String>[
                            _prefs.urlBase,
                            ..._prefs.recentEndpoints
                                .where((e) => e != _prefs.urlBase),
                          ].take(6).toList();
                          if (!mounted) return;
                          setState(() {}); // refresca la ficha principal
                          if (!ctx.mounted) return;
                          AppNavigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Dirección guardada')));
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final recents = _prefs.recentEndpoints;
                    if (recents.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 24),
                        Text('Recientes',
                            style: Theme.of(ctx).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: recents.take(6).map((e) {
                            return ActionChip(
                              avatar: const Icon(Icons.history, size: 18),
                              label: Text(e, overflow: TextOverflow.ellipsis),
                              onPressed: () => setModalState(
                                  () => aplicarRecienteAloscampos(e)),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ---------- Secciones ----------

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sin botón de volver; título centrado para consistencia
      appBar: AppBar(
        leading: widget.showMenuIcon
            ? IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            //AppScaffoldKey.homeKey.currentState?.openDrawer();
            Scaffold.of(context).openDrawer();
          },
        ) : null,
        backgroundColor: colorRojoBase(),
        title: const Text('Configuración'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Buscar',
            onPressed: () {
              // TODO: búsqueda de opciones (si aplica)
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ¡Aquí está! Se mostrará en la parte superior de la pantalla.
          const ConnectivityBanner(),
          // -------- Conexión --------
          _sectionHeader('Conexión'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(context).withOpacity(0.15),
                child: Icon(_statusIcon(), color: _statusColor(context)),
              ),
              title: const Text('Dirección del servidor'),
              subtitle: Text(
                _prefs.urlBase.isEmpty ? 'No configurada' : _prefs.urlBase,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Copiar',
                    onPressed: _prefs.urlBase.isEmpty ? null : _copiar,
                    icon: const Icon(Icons.copy),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _openEditServerSheet,
            ),
          ),

          // // -------- Preferencias --------
          _sectionHeader('Preferencias'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                // Rutas
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Rutas'),
                  subtitle: _rutasAsignadas.isEmpty
                      ? const Text('Sin rutas asignadas')
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickRutas,
                ),
                if (_rutasAsignadas.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _rutasAsignadas
                          .map((r) => Chip(label: Text(r.descripcion)))
                          .toList(),
                    ),
                  ),
                const Divider(height: 0),

                // Fecha de trabajo
                ListTile(
                  leading: const Icon(Icons.today),
                  title: const Text('Fecha de trabajo'),
                  subtitle: Text(
                    _fechaTrabajo != null
                        ? _fmt(_fechaTrabajo!)
                        : 'Seleccione fecha',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickFechaTrabajo,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('IVA'),
                  subtitle: Text(_fmtPct(_prefs.iva)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editTax(
                    titulo: 'IVA',
                    valorActual: _prefs.iva,
                    onSave: (v) => setState(() => _prefs.iva = v),
                  ),
                ),
              ],
            ),
          ),

          // -------- Cuenta --------
          if (_canShowLogout) ...[
            _sectionHeader('Cuenta'),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Cambiar contraseña'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AppNavigator.pushNamed(AppRoutes.cambiarClave),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                final salir = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirmar'),
                    content: const Text('¿Desea cerrar la sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                );
                if (salir == true && mounted) {
                  // Limpia tokens/estado y navega a login
                  _prefs.access_token = '';
                  await detenerServicioUbicacion();
                  AppNavigator.goToLogin();
                }
              },
            ),
          ],
          // -------- Acerca de --------
          _sectionHeader('Acerca de'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión'),
            subtitle: Text('1.0.0 (build 1)'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
