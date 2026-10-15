import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Indica si el permiso de ubicación en segundo plano ("Permitir siempre")
/// está concedido en este momento. Útil para reflejar en la UI (ej. menú
/// lateral) cuando el usuario lo desactivó desde Ajustes fuera de la app.
Future<bool> tienePermisoUbicacionSiempre() => Permission.locationAlways.isGranted;

/// Solicita el permiso de ubicación en segundo plano ("Permitir siempre"),
/// mostrando primero una explicación (sube la tasa de aceptación) y pidiendo
/// los permisos en el orden que exige el sistema operativo: primero
/// foreground, luego background. Si el usuario ya lo rechazó de forma
/// permanente, ofrece abrir Ajustes en vez de insistir con un diálogo del
/// sistema que ya no volverá a aparecer.
Future<void> solicitarPermisoUbicacionSiempre(BuildContext context) async {
  if (await Permission.locationAlways.isGranted) return;

  if (!context.mounted) return;
  final continuar = await _mostrarRationale(context);
  if (continuar != true) return;

  final foreground = await Permission.location.request();
  if (!foreground.isGranted) {
    if (foreground.isPermanentlyDenied && context.mounted) {
      await _mostrarDialogoAjustes(context);
    }
    return;
  }

  final backgroundConcedido = await _solicitarUbicacionSiempre();
  if (!backgroundConcedido && context.mounted) {
    await _mostrarDialogoAjustes(context);
  }
}

/// En iOS, tras aprobar "Permitir siempre" en el diálogo nativo, el estado
/// que devuelve `request()` a veces todavía refleja el valor previo (el SO
/// actualiza CLAuthorizationStatus con un pequeño delay respecto a cuándo
/// se resuelve el Future). Se vuelve a leer el estado tras una breve espera
/// antes de asumir que quedó denegado.
Future<bool> _solicitarUbicacionSiempre() async {
  final status = await Permission.locationAlways.request();
  debugPrint('[Permisos] locationAlways.request() -> $status');
  if (status.isGranted) return true;

  await Future.delayed(const Duration(milliseconds: 700));
  final statusReleido = await Permission.locationAlways.status;
  debugPrint('[Permisos] locationAlways.status (releído) -> $statusReleido');
  return statusReleido.isGranted;
}

Future<bool?> _mostrarRationale(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Ubicación en segundo plano'),
      content: const Text(
        'Dipalza necesita tu ubicación todo el tiempo para que el equipo '
        'de logística pueda seguir tu recorrido y coordinar rutas, incluso '
        'con la app cerrada. En la siguiente pantalla, elige "Permitir '
        'todo el tiempo".',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}

/// Pide al sistema que excluya la app de la optimización de batería (Doze /
/// app standby). Mitiga que el servicio de ubicación en segundo plano tarde
/// en arrancar o se corte en fabricantes agresivos con el ahorro de batería
/// (Samsung "Device Care" en particular) -- causa más probable de los
/// `ForegroundServiceDidNotStartInTimeException` reportados por clientes. No
/// bloquea el flujo si el usuario la rechaza: es una mitigación, no un
/// permiso indispensable para que la app funcione.
Future<void> solicitarExclusionDeOptimizacionDeBateria(BuildContext context) async {
  if (await Permission.ignoreBatteryOptimizations.isGranted) return;

  if (!context.mounted) return;
  final continuar = await _mostrarRationaleBateria(context);
  if (continuar != true) return;

  final status = await Permission.ignoreBatteryOptimizations.request();
  debugPrint('[Permisos] ignoreBatteryOptimizations.request() -> $status');
}

Future<bool?> _mostrarRationaleBateria(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Optimización de batería'),
      content: const Text(
        'Para que el seguimiento de ubicación no se corte en segundo plano, '
        'permite que Dipalza se excluya de la optimización de batería en '
        'la siguiente pantalla.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}

Future<void> _mostrarDialogoAjustes(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Permiso de ubicación pendiente'),
      content: const Text(
        'Sin este permiso no podremos reportar tu posición al equipo de '
        'logística. Puedes activarlo manualmente en Ajustes > Ubicación > '
        'Permitir todo el tiempo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            openAppSettings();
          },
          child: const Text('Abrir Ajustes'),
        ),
      ],
    ),
  );
}
