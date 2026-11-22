import 'dart:async';

import 'package:dipalza_movil/src/bloc/cambiar_clave_bloc.dart';
import 'package:dipalza_movil/src/bloc/login_bloc.dart';
import 'package:dipalza_movil/src/log/crash_reporting.dart';
import 'package:dipalza_movil/src/log/db_log_provider.dart';
import 'package:dipalza_movil/src/page/config/server_setup.page.dart';
import 'package:dipalza_movil/src/page/login/auth_gate.dart';
import 'package:dipalza_movil/src/services/api_client.dart';
import 'package:dipalza_movil/src/services/background_location_service.dart';
import 'package:dipalza_movil/src/services/connectivity_service.dart';
import 'package:dipalza_movil/src/services/diagnostico_gps.dart';
import 'package:dipalza_movil/src/services/locator.dart';
import 'package:dipalza_movil/src/services/posicion_queue.dart';
import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:dipalza_movil/src/share/app_router.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:dipalza_movil/src/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'src/bloc/condicion_venta_bloc.dart';

// 1. Función global para el servicio
@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  final prefs = PreferenciasUsuario();
  await prefs.initPrefs();
  final apiClient = ApiClient();
  DBLogProvider.db.nuevoLog(creaLogInfo('BackgroundService', 'onStart',
      'baseUrl=${apiClient.dio.options.baseUrl}'));

  // Diagnóstico remoto (Crashlytics) de los huecos del servicio GPS: este
  // isolate no comparte la inicialización de Firebase de la app principal.
  final diagnostico = await _crearDiagnosticoGps(prefs);
  await diagnostico.alIniciarServicio(prefs.ultimoCicloGps);

  // Reenvía a la UI (isolate principal) la sesión expirada detectada acá:
  // el ApiClient de este isolate es una instancia independiente, su stream
  // onSessionExpired no llega solo al listener de MyApp.
  apiClient.onSessionExpired.listen((_) => service.invoke(kMensajeSesionExpirada));

  // Este isolate vive desde el arranque en frío y no se recrea entre
  // logins: tras uno nuevo, releer las credenciales (en vez de esperar al
  // próximo tick de 30 s) y descartar cualquier flag de refresh colgado de
  // la sesión anterior (ver notificarCredencialesActualizadas).
  service.on(kMensajeCredencialesActualizadas).listen((_) async {
    await prefs.initPrefs();
    apiClient.resetEstadoRefresh();
    _registrarBG('Credenciales releídas tras login');
    diagnostico.evento('Credenciales releídas tras login');
    await _identificarVendedor(diagnostico, prefs);
  });

  // Android e iOS: timer cada 30 segundos. Se usa un timer en ambas
  // plataformas (en vez de un stream por distancia en iOS) para que la
  // posición se reporte de forma regular aunque el dispositivo esté quieto.
  final locationSettings = defaultTargetPlatform == TargetPlatform.iOS
      ? AppleSettings(
          accuracy: LocationAccuracy.high,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        )
      : AndroidSettings(
          accuracy: LocationAccuracy.high,
        );

  _registrarBG('Servicio iniciado, timer de 30 s creado');

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    // Todo el tick va dentro de un try: una excepción no capturada en un
    // Timer mata el isolate y el servicio deja de reportar sin dejar rastro.
    try {
      _registrarBG('Tick');
      prefs.ultimoCicloGps = await diagnostico.alCiclo();

      // ✅ Guard antes de pedir posición
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _registrarBG('GPS desactivado, skip envío');
        await diagnostico.alFallarGps('GPS desactivado');
        return; // espera al próximo tick
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _registrarBG('Permiso de ubicación denegado, skip envío');
        await diagnostico.alFallarGps('Permiso de ubicación denegado');
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 25));
      diagnostico.alObtenerPosicion();
      final enviado = await _procesarPosicion(apiClient, posicion);
      if (!enviado) diagnostico.evento('Envío falló, posición encolada');
      _registrarBG((enviado
              ? 'Ciclo OK (enviado)'
              : 'Ciclo OK (encolado, envío falló)') +
          ': ${posicion.latitude}, ${posicion.longitude}');
    } catch (e, st) {
      _registrarBG('Error en tick: $e\n$st', error: true);
      await diagnostico.alFallarGps(e is TimeoutException ? 'Tiempo agotado esperando el GPS' : 'Error: ${e.runtimeType}');
    }
  });

  return true;
}

/// Inicializa Firebase en el isolate del servicio y arma el diagnóstico. Si
/// Firebase falla, el diagnóstico sigue funcionando sin enviar nada.
Future<DiagnosticoGps> _crearDiagnosticoGps(PreferenciasUsuario prefs) async {
  ReporteDiagnostico reporte;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    reporte = ReporteCrashlytics();
  } catch (e) {
    _registrarBG('Crashlytics no disponible en el servicio: $e', error: true);
    reporte = _ReporteNulo();
  }
  final diagnostico = DiagnosticoGps(reporte: reporte, estadoTelefono: _estadoTelefono);
  await _identificarVendedor(diagnostico, prefs);
  return diagnostico;
}

Future<void> _identificarVendedor(DiagnosticoGps diagnostico, PreferenciasUsuario prefs) async {
  try {
    await diagnostico.identificar('${prefs.userName} (vendedor ${prefs.vendedor})');
  } catch (_) {}
}

/// Estado del teléfono que acompaña cada reporte de diagnóstico.
Future<Map<String, Object>> _estadoTelefono() async {
  final info = await PackageInfo.fromPlatform();
  return {
    'gps_encendido': await Geolocator.isLocationServiceEnabled(),
    'permiso_ubicacion': (await Geolocator.checkPermission()).name,
    'bateria_sin_restriccion': await Permission.ignoreBatteryOptimizations.isGranted,
    'version_app': '${info.version}+${info.buildNumber}',
  };
}

class _ReporteNulo implements ReporteDiagnostico {
  @override
  void miga(String mensaje) {}
  @override
  Future<void> identificar(String usuario) async {}
  @override
  Future<void> reportar(String motivo, Map<String, Object> claves) async {}
}

/// Deja el mensaje en logcat (tag flutter, también en release) y en la
/// tabla de logs de la app, visible desde la pantalla de logs.
void _registrarBG(String mensaje, {bool error = false}) {
  debugPrint('[BG] $mensaje');
  final log = error
      ? creaLogError('BackgroundService', 'onStart', mensaje)
      : creaLogInfo('BackgroundService', 'onStart', mensaje);
  DBLogProvider.db.nuevoLog(log).catchError((_) => 0);
}

/// Envía la posición actual (reintentando antes lo que haya quedado
/// pendiente de ciclos anteriores). Si el envío falla por falta de
/// conectividad u otro error, la posición se encola localmente en vez de
/// perderse.
Future<bool> _procesarPosicion(ApiClient apiClient, Position position) async {
  final prefs = PreferenciasUsuario();
  await prefs.initPrefs();
  if (prefs.access_token.isEmpty || prefs.vendedor.isEmpty) return false;

  await _vaciarColaPendiente(apiClient);

  final actual = PosicionPendiente(
    vendedorId: prefs.vendedor,
    vendedorCodigo: prefs.tipo,
    latitud: position.latitude,
    longitud: position.longitude,
    fechaHora: DateTime.now().toIso8601String(),
  );

  final enviado = await _enviarPosicion(apiClient, actual);
  if (!enviado) {
    await PosicionQueueDB.instance.encolar(actual);
  }
  return enviado;
}

Future<bool> _enviarPosicion(ApiClient apiClient, PosicionPendiente posicion) async {
  try {
    await apiClient.dio.post('/api/posicion', data: posicion.toMap());
    return true;
  } catch (e) {
    debugPrint('Error en envío de posición: $e');
    DBLogProvider.db.nuevoLog(
        creaLogError('BackgroundService', '_enviarPosicion', e.toString()));
    return false;
  }
}

Future<void> _vaciarColaPendiente(ApiClient apiClient) async {
  final pendientes = await PosicionQueueDB.instance.obtenerPendientes();
  for (final pendiente in pendientes) {
    final enviado = await _enviarPosicion(apiClient, pendiente);
    if (!enviado) break; // el servidor sigue sin responder, se reintenta en el próximo ciclo
    await PosicionQueueDB.instance.eliminar(pendiente.id!);
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // ✅ Crear el canal ANTES de configurar el servicio (Android 8+)
  final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
  await flnp
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
    'dipalza_location_channel',        // mismo ID que en AndroidConfiguration
    'Dipalza Ubicación',
    description: 'Monitoreo de ubicación para logística',
    importance: Importance.low,        // low evita sonido en notif persistente
  ));

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      // Se inicia abajo, solo si no está corriendo (ver iniciarServicioUbicacion).
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'dipalza_location_channel',
      initialNotificationTitle: 'Dipalza en ejecución',
      initialNotificationContent: 'Monitoreando ubicación para logística',
      foregroundServiceNotificationId: 888, // ✅ ID fijo requerido en v5+
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onStart,
    ),
  );

  // En iOS el arranque lo hace configure (autoStart de IosConfiguration).
  if (defaultTargetPlatform == TargetPlatform.android) {
    await iniciarServicioUbicacion(
      estaCorriendo: service.isRunning,
      iniciar: service.startService,
    );
  }
}
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es_CL', null);

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Habilitado también en debug (por ahora) para poder probar el flujo
    // completo de Crashlytics desde el simulador/emulador sin tener que
    // compilar en release. Si más adelante el dashboard se llena de ruido
    // por corridas de desarrollo, volver a condicionar con `!kDebugMode`.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    configurarCapturaDeErrores();

    final prefs = new PreferenciasUsuario();
    await prefs.initPrefs();

    // ✅ Solicitar permiso de notificación (requerido por el foreground
    // service en Android 13+). El permiso de ubicación se pide más adelante,
    // en Home, con una explicación previa (ver location_permission_service.dart).
    await Permission.notification.request();

    setupLocator();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ConnectivityService()..initialize(),
          ),
          Provider<CondicionVentaBloc>(
            create: (_) => locator<CondicionVentaBloc>(),
            dispose: (_, bloc) => bloc.dispose(),
          ),
          Provider<LoginBloc>(
            create: (_) => LoginBloc(),
            dispose: (_, bloc) => bloc.dispose(),
          ),
          Provider<CambiarClaveBloc>(
            create: (_) => CambiarClaveBloc(),
            dispose: (_, bloc) => bloc.dispose(),
          ),
        ],
        child: MyApp(), // Tu widget principal
      ),
    );

    // El servicio se inicia después del primer frame. Si se pide antes de
    // runApp, Android exige startForeground dentro de 5 s mientras el hilo
    // principal todavía está armando la app (ForegroundServiceDidNotStartInTimeException).
    WidgetsBinding.instance.addPostFrameCallback((_) => initializeService());
  }, capturarErrorDeZona);
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _sessionSub;
  StreamSubscription? _sessionExpiradaBackgroundSub;

  @override
  void initState() {
    super.initState();
    _sessionSub = ApiClient().onSessionExpired.listen((_) {
      if (mounted) {
        _handleSessionExpired();
      }
    });

    // La sesión también puede expirar dentro del isolate del servicio de
    // ubicación en segundo plano; ese ApiClient reenvía el evento acá.
    _sessionExpiradaBackgroundSub =
        FlutterBackgroundService().on(kMensajeSesionExpirada).listen((_) {
      if (mounted) {
        _handleSessionExpired();
      }
    });
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    _sessionExpiradaBackgroundSub?.cancel();
    super.dispose();
  }

  void _handleSessionExpired() async {
    final prefs = PreferenciasUsuario();
    await prefs.borrarCredenciales();
    await detenerServicioUbicacion();
    AppNavigator.goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    AppTheme.createAppColors(
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diplaza App.',
      navigatorKey: AppNavigator.navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      home: PreferenciasUsuario().servidorHost.isEmpty
          ? const ServerSetupPage()
          : const AuthGate(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CL')],
      locale: const Locale('es', 'CL'),
    );
  }
}
