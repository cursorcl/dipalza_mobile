import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Destino de los diagnósticos del servicio GPS. En la app es Crashlytics;
/// en los tests, un falso.
abstract class ReporteDiagnostico {
  /// Evento del servicio, guardado como miga de pan: viaja con el próximo reporte.
  void miga(String mensaje);

  /// Asocia los reportes al vendedor, para buscarlos por usuario en Firebase.
  Future<void> identificar(String usuario);

  /// Envía un reporte no fatal con el motivo y el estado del teléfono.
  Future<void> reportar(String motivo, Map<String, Object> claves);
}

/// Detecta, dentro del servicio GPS en segundo plano, los huecos y las fallas
/// que producen rectas falsas en el recorrido, y los reporta sin que el
/// vendedor intervenga:
/// - el servicio se reinició y su último ciclo es de hace más de [umbralHueco]
///   (Android lo mató);
/// - entre dos ciclos del mismo servicio pasó más de [umbralHueco] (el timer
///   quedó congelado);
/// - el GPS no entregó posición en [fallasParaReportar] ciclos seguidos.
///
/// Nunca lanza excepción: el diagnóstico no debe afectar el envío de posiciones.
class DiagnosticoGps {
  final ReporteDiagnostico _reporte;
  final DateTime Function() _ahora;
  final Future<Map<String, Object>> Function() _estadoTelefono;
  final Duration umbralHueco;
  final int fallasParaReportar;

  DateTime? _ultimoCiclo;
  int _fallasSeguidas = 0;

  DiagnosticoGps({
    required ReporteDiagnostico reporte,
    required Future<Map<String, Object>> Function() estadoTelefono,
    DateTime Function()? ahora,
    this.umbralHueco = const Duration(minutes: 2),
    this.fallasParaReportar = 5,
  })  : _reporte = reporte,
        _estadoTelefono = estadoTelefono,
        _ahora = ahora ?? DateTime.now;

  /// Al arrancar el servicio: [ultimoCicloGuardado] es la hora del último
  /// ciclo del proceso anterior (persistida), o null si nunca corrió.
  Future<void> alIniciarServicio(DateTime? ultimoCicloGuardado) async {
    _reporte.miga('Servicio GPS iniciado');
    if (ultimoCicloGuardado == null) return;
    final hueco = _ahora().difference(ultimoCicloGuardado);
    if (hueco > umbralHueco) {
      await _reportarHueco('Servicio GPS reiniciado tras ${hueco.inMinutes} min sin ciclos', hueco);
    }
  }

  /// En cada ciclo del timer. Devuelve la hora que hay que persistir como
  /// último ciclo.
  Future<DateTime> alCiclo() async {
    final ahora = _ahora();
    _reporte.miga('Ciclo ${_hora(ahora)}');
    final anterior = _ultimoCiclo;
    _ultimoCiclo = ahora;
    if (anterior != null) {
      final hueco = ahora.difference(anterior);
      if (hueco > umbralHueco) {
        await _reportarHueco('Servicio GPS sin ciclos durante ${hueco.inMinutes} min', hueco);
      }
    }
    return ahora;
  }

  /// El ciclo terminó sin posición (GPS apagado, sin permiso, tiempo agotado...).
  Future<void> alFallarGps(String motivo) async {
    _reporte.miga('Sin posición: $motivo');
    _fallasSeguidas++;
    if (_fallasSeguidas == fallasParaReportar) {
      await _reportar('GPS sin posición en $fallasParaReportar ciclos seguidos', {'ultimo_error': motivo});
    }
  }

  /// El ciclo obtuvo posición: termina la racha de fallas.
  void alObtenerPosicion() {
    _fallasSeguidas = 0;
  }

  /// Asocia los próximos reportes al vendedor.
  Future<void> identificar(String usuario) => _reporte.identificar(usuario);

  /// Evento suelto del servicio (envío fallido, credenciales releídas...).
  void evento(String mensaje) => _reporte.miga(mensaje);

  Future<void> _reportarHueco(String motivo, Duration hueco) =>
      _reportar(motivo, {'hueco_minutos': hueco.inMinutes});

  Future<void> _reportar(String motivo, Map<String, Object> extra) async {
    Map<String, Object> estado;
    try {
      estado = await _estadoTelefono();
    } catch (e) {
      estado = {'estado_telefono_error': e.toString()};
    }
    try {
      await _reporte.reportar(motivo, {...estado, ...extra});
    } catch (_) {
      // Sin Crashlytics disponible no hay a quién avisar; el log local sigue igual.
    }
  }

  static String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
}

/// Envía los diagnósticos a Firebase Crashlytics como reportes no fatales.
class ReporteCrashlytics implements ReporteDiagnostico {
  final FirebaseCrashlytics _crashlytics;

  ReporteCrashlytics([FirebaseCrashlytics? crashlytics])
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  @override
  void miga(String mensaje) {
    unawaited(_crashlytics.log(mensaje).catchError((_) {}));
  }

  @override
  Future<void> identificar(String usuario) => _crashlytics.setUserIdentifier(usuario);

  @override
  Future<void> reportar(String motivo, Map<String, Object> claves) async {
    for (final entrada in claves.entries) {
      await _crashlytics.setCustomKey(entrada.key, entrada.value);
    }
    await _crashlytics.recordError(DiagnosticoGpsException(motivo), StackTrace.current,
        reason: motivo, fatal: false);
  }
}

/// Excepción que agrupa en Crashlytics los reportes del servicio GPS.
class DiagnosticoGpsException implements Exception {
  final String motivo;
  DiagnosticoGpsException(this.motivo);

  @override
  String toString() => 'DiagnosticoGps: $motivo';
}
