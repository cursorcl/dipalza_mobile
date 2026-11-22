import 'package:flutter_background_service/flutter_background_service.dart';

/// Nombre del mensaje que el isolate del servicio de ubicación usa para
/// avisarle a la UI (isolate principal) que la sesión expiró. El ApiClient
/// del servicio vive en un isolate distinto al de la UI, por lo que su
/// stream `onSessionExpired` no llega solo — hay que reenviarlo a través
/// del canal de mensajería de flutter_background_service.
const String kMensajeSesionExpirada = 'sessionExpired';

/// Inicia el servicio de ubicación solo si no está corriendo.
///
/// Pedirle a Android que inicie un servicio en primer plano que ya corre
/// hace que el plugin no vuelva a llamar a startForeground() y Android mata
/// el proceso completo (ForegroundServiceDidNotStartInTimeException), con lo
/// que también se corta el GPS. Pasaba cada vez que el vendedor volvía a abrir
/// la app con el servicio vivo.
Future<void> iniciarServicioUbicacion({
  required Future<bool> Function() estaCorriendo,
  required Future<bool> Function() iniciar,
}) async {
  if (await estaCorriendo()) return;
  await iniciar();
}

/// Detiene el servicio de ubicación en segundo plano (logout / sesión
/// expirada). Si el usuario vuelve a iniciar sesión sin reiniciar la app,
/// el servicio permanece detenido hasta el próximo arranque en frío.
Future<void> detenerServicioUbicacion() async {
  final service = FlutterBackgroundService();
  final running = await service.isRunning();
  if (running) {
    service.invoke('stopService');
  }
}

/// Nombre del mensaje que la UI (isolate principal) usa para avisarle al
/// isolate del servicio de ubicación que hay credenciales nuevas (login
/// recién hecho). El ApiClient/PreferenciasUsuario de ese isolate vive
/// desde el arranque en frío y no se recrea entre logins — sin este aviso,
/// puede seguir usando tokens/flags de refresh de una sesión anterior hasta
/// el próximo tick de 30 s (o indefinidamente si quedó un estado de
/// "sesión expirada" ya resuelto por el login nuevo).
const String kMensajeCredencialesActualizadas = 'credencialesActualizadas';

/// Avisa al servicio de ubicación que vuelva a leer las credenciales y
/// descarte cualquier estado de refresh colgado de la sesión anterior.
/// Llamar justo después de un login exitoso. Si el servicio no está
/// corriendo (p.ej. permisos de ubicación denegados) no hace nada.
Future<void> notificarCredencialesActualizadas() async {
  final service = FlutterBackgroundService();
  final running = await service.isRunning();
  if (running) {
    service.invoke(kMensajeCredencialesActualizadas);
  }
}
