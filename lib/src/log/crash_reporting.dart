import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'db_log_provider.dart';

/// Registra los manejadores globales de error para que toda caída de la app
/// quede (a) en Crashlytics (con stack trace, para diagnosticar caídas
/// nativas y de Dart en dispositivos remotos) y (b) en el log local SQLite
/// ya existente (visible en la pantalla de logs de la propia app).
///
/// Debe llamarse dentro de la misma zona que ejecuta runApp() -- ver
/// runZonedGuarded en main().
void configurarCapturaDeErrores() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    _registrarEnLogLocal('FlutterError', details.exceptionAsString());
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    _registrarEnLogLocal('PlatformDispatcher', error.toString());
    return true;
  };
}

/// Captura cualquier error que escape de la zona de la app (por ejemplo, en
/// un callback async sin try/catch) -- último respaldo, además de los dos
/// manejadores de arriba.
void capturarErrorDeZona(Object error, StackTrace stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  _registrarEnLogLocal('ZonaPrincipal', error.toString());
}

void _registrarEnLogLocal(String origen, String info) {
  DBLogProvider.db.nuevoLog(creaLogError(origen, 'errorNoCapturado', info));
}
