import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  static final PreferenciasUsuario _instancia = PreferenciasUsuario._internal();

  factory PreferenciasUsuario() {
    return _instancia;
  }

  PreferenciasUsuario._internal();

  late SharedPreferences _prefs;
  final _storage = const FlutterSecureStorage();

  // --- VARIABLES EN MEMORIA (Para acceso rápido y síncrono) ---
  // Esto evita tener que poner 'await' en cada llamada a token en tu UI
  String _tokenInMemory = '';
  String _refreshTokenInMemory = '';
  String _passwordInMemory = '';
  String _userNameInMemory = '';

  // --- INICIALIZACIÓN ---
  Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    // Leemos del almacenamiento seguro y cargamos en RAM al inicio
    _tokenInMemory = await _storage.read(key: 'token') ?? '';
    _refreshTokenInMemory = await _storage.read(key: 'refreshToken') ?? '';
    _passwordInMemory = await _storage.read(key: 'password') ?? '';
    _userNameInMemory = await _storage.read(key: 'userName') ?? '';

    _migrarUrlServicioLegado();
  }

  /// Migra el valor legado 'urlServicio' ('host:puerto', siempre http) al
  /// nuevo almacenamiento separado (host/puerto/esquema), una sola vez.
  /// Preserva el comportamiento actual para dispositivos ya configurados:
  /// el esquema migrado siempre es 'http', nunca se fuerza https.
  void _migrarUrlServicioLegado() {
    if ((_prefs.getString('servidorHost') ?? '').isNotEmpty) return;
    final legado = _prefs.getString('urlServicio') ?? '';
    if (legado.isEmpty) return;

    final idx = legado.lastIndexOf(':');
    final host = idx == -1 ? legado : legado.substring(0, idx);
    final puerto = idx == -1 ? '' : legado.substring(idx + 1);

    _prefs.setString('servidorHost', host);
    _prefs.setString('servidorPuerto', puerto);
    _prefs.setString('servidorEsquema', 'http');
  }

  // =======================================================
  //  SECCIÓN SEGURA (FlutterSecureStorage + Memoria)
  // =======================================================

  String get access_token => _tokenInMemory;

  set access_token(String value) {
    _tokenInMemory = value; // Actualizamos memoria
    _storage.write(
        key: 'token', value: value); // Guardamos seguro asíncronamente
  }

  String get refreshToken => _refreshTokenInMemory;

  set refreshToken(String value) {
    _refreshTokenInMemory = value;
    _storage.write(key: 'refreshToken', value: value);
  }

  String get password => _passwordInMemory;

  set password(String value) {
    _passwordInMemory = value;
    _storage.write(key: 'password', value: value);
  }

  String get userName => _userNameInMemory;

  set userName(String value) {
    _userNameInMemory = value;
    _storage.write(key: 'userName', value: value);
  }

  // Método para borrar datos sensibles al hacer Logout
  Future<void> borrarCredenciales() async {
    _tokenInMemory = '';
    _refreshTokenInMemory = '';
    _passwordInMemory = '';
    _userNameInMemory = '';
    await _storage.deleteAll();
  }

  // =======================================================
  //  SECCIÓN PREFERENCIAS (SharedPreferences - Se mantienen igual)
  // =======================================================

  String get vendedor {
    return _prefs.getString('vendedor') ?? '';
  }

  set vendedor(String value) {
    _prefs.setString('vendedor', value);
  }

  String get tipo {
    return _prefs.getString('tipo') ?? '';
  }

  set tipo(String value) {
    _prefs.setString('tipo', value);
  }

  String get name {
    return _prefs.getString('name') ?? "";
  }

  set name(String value) {
    _prefs.setString('name', value);
  }

  String get urlServicio {
    return _prefs.getString('urlServicio') ?? '';
  }

  set urlServicio(String value) {
    _prefs.setString('urlServicio', value);
  }

  String get servidorHost {
    return _prefs.getString('servidorHost') ?? '';
  }

  set servidorHost(String value) {
    _prefs.setString('servidorHost', value);
  }

  String get servidorPuerto {
    return _prefs.getString('servidorPuerto') ?? '';
  }

  set servidorPuerto(String value) {
    _prefs.setString('servidorPuerto', value);
  }

  String get servidorEsquema {
    return _prefs.getString('servidorEsquema') ?? 'https';
  }

  set servidorEsquema(String value) {
    _prefs.setString('servidorEsquema', value);
  }

  /// URL base lista para usar ('esquema://host[:puerto]'), o '' si no hay
  /// servidor configurado. Fuente única de verdad para armar cualquier
  /// request al backend.
  String get urlBase {
    final host = servidorHost;
    if (host.isEmpty) return '';
    final puerto = servidorPuerto;
    return puerto.isEmpty
        ? '$servidorEsquema://$host'
        : '$servidorEsquema://$host:$puerto';
  }

  String get ruta {
    return _prefs.getString('ruta') ?? '';
  }

  set ruta(String value) {
    _prefs.setString('ruta', value);
  }

  List<String> get rutasAsignadas {
    return _prefs.getStringList('rutasAsignadas') ?? [];
  }

  set rutasAsignadas(List<String> value) {
    _prefs.setStringList('rutasAsignadas', value);
  }

  int get reporte {
    return _prefs.getInt('reporte') ?? 300000;
  }

  set reporte(int value) {
    _prefs.setInt('reporte', value);
  }

  List<String> get recentEndpoints {
    return _prefs.getStringList('serviceHistory') ?? [];
  }

  set recentEndpoints(List<String> value) {
    _prefs.setStringList('serviceHistory', value);
  }

  DateTime get fechaFacturacion {
    final fechaGuardada = _prefs.getString('fechaFacturacion');
    if (fechaGuardada == null) {
      return DateTime.now().add(const Duration(days: 1));
    }
    return DateTime.tryParse(fechaGuardada) ??
        DateTime.now().add(const Duration(days: 1));
  }

  set fechaFacturacion(DateTime value) {
    _prefs.setString('fechaFacturacion', value.toIso8601String());
  }

  double get iva {
    return _prefs.getDouble('iva') ?? 19.0;
  }

  set iva(double value) {
    _prefs.setDouble('iva', value);
  }

  deleteAll() {
    _prefs.clear();
    _storage.deleteAll();
  }
}
