import 'dart:async';

import 'package:dipalza_movil/src/bloc/cambiar_clave_bloc.dart';
import 'package:dipalza_movil/src/bloc/login_bloc.dart';
import 'package:dipalza_movil/src/page/config/server_setup.page.dart';
import 'package:dipalza_movil/src/page/login/auth_gate.dart';
import 'package:dipalza_movil/src/services/api_client.dart';
import 'package:dipalza_movil/src/services/background_location_service.dart';
import 'package:dipalza_movil/src/services/connectivity_service.dart';
import 'package:dipalza_movil/src/services/locator.dart';
import 'package:dipalza_movil/src/services/posicion_queue.dart';
import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:dipalza_movil/src/share/app_router.dart';
import 'package:dipalza_movil/src/share/app_routes.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:dipalza_movil/src/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:provider/provider.dart';

import 'src/bloc/condicion_venta_bloc.dart';

// 1. Función global para el servicio
@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  final prefs = PreferenciasUsuario();
  await prefs.initPrefs();
  final apiClient = ApiClient();

  // Reenvía a la UI (isolate principal) la sesión expirada detectada acá:
  // el ApiClient de este isolate es una instancia independiente, su stream
  // onSessionExpired no llega solo al listener de MyApp.
  apiClient.onSessionExpired.listen((_) => service.invoke(kMensajeSesionExpirada));

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

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    // ✅ Guard antes de pedir posición
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[BG] GPS desactivado, skip envío');
      return; // espera al próximo tick
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[BG] Permiso de ubicación denegado, skip envío');
      return;
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      await _procesarPosicion(apiClient, posicion);
    } catch (e) {
      debugPrint('[BG] Error obteniendo posición: $e');
    }
  });

  return true;
}

/// Envía la posición actual (reintentando antes lo que haya quedado
/// pendiente de ciclos anteriores). Si el envío falla por falta de
/// conectividad u otro error, la posición se encola localmente en vez de
/// perderse.
Future<void> _procesarPosicion(ApiClient apiClient, Position position) async {
  final prefs = PreferenciasUsuario();
  await prefs.initPrefs();
  if (prefs.access_token.isEmpty || prefs.vendedor.isEmpty) return;

  await _vaciarColaPendiente(apiClient);

  final actual = PosicionPendiente(
    vendedorId: prefs.vendedor,
    latitud: position.latitude,
    longitud: position.longitude,
    fechaHora: DateTime.now().toIso8601String(),
  );

  final enviado = await _enviarPosicion(apiClient, actual);
  if (!enviado) {
    await PosicionQueueDB.instance.encolar(actual);
  }
}

Future<bool> _enviarPosicion(ApiClient apiClient, PosicionPendiente posicion) async {
  try {
    await apiClient.dio.post('/api/posicion', data: posicion.toMap());
    return true;
  } catch (e) {
    debugPrint('Error en envío de posición: $e');
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
      autoStart: true,
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
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);


  WidgetsFlutterBinding.ensureInitialized();


  final prefs = new PreferenciasUsuario();
  await prefs.initPrefs();

  // ✅ Solicitar permiso de notificación (requerido por el foreground
  // service en Android 13+). El permiso de ubicación se pide más adelante,
  // en Home, con una explicación previa (ver location_permission_service.dart).
  await Permission.notification.request();

  setupLocator();
  await initializeService();
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
