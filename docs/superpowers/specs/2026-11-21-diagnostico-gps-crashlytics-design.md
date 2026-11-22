# Diagnóstico remoto del servicio GPS con Crashlytics — Diseño

Fecha: 2026-11-21 · Repo: `dipalza_mobile`

## Intención

En producción hay huecos en el recorrido de los vendedores: el 18-11, jzamora pasó 5
huecos en movimiento (unos 2 h 20 min) sin posiciones, y el mapa los dibuja como rectas
falsas. El log local del servicio GPS (SQLite) no se puede leer sin que el vendedor
intervenga, y el MDM no accede a los datos de la app. Se quiere ver **cuándo y por
qué** se corta el servicio en cada teléfono, sin intervención del vendedor.

## Enfoque (aprobado por el usuario)

Aprovechar Firebase Crashlytics, que ya está integrado para las caídas (PR #31), y
**no** agregar backend:

1. Inicializar Firebase en el isolate del servicio en segundo plano e identificar los
   reportes con el usuario del vendedor (`setUserIdentifier`).
2. Cada evento del servicio (ciclo, GPS apagado, permiso denegado, error, envío fallido)
   se guarda además como miga de pan (`FirebaseCrashlytics.log`).
3. Se envía un **reporte no fatal** cuando:
   - **el servicio se reinicia** y su último ciclo guardado tiene más de 2 min
     (Android lo mató: es el caso que más interesa);
   - **entre dos ciclos** del mismo servicio pasan más de 2 min (timer congelado);
   - el GPS **falla 5 ciclos seguidos** (se reporta una vez por racha).
4. Cada reporte lleva claves (`setCustomKey`) con el estado del teléfono: GPS
   encendido, permiso de ubicación, exclusión de optimización de batería y versión
   de la app.

## Decisiones de Claude

- **Sin nivel de batería ni ahorro de energía:** requieren un paquete nuevo (`battery_plus`);
  se deja fuera para no sumar dependencias. Se puede agregar después.
- **La hora del último ciclo se guarda en SharedPreferences** del isolate del servicio
  en cada ciclo, para detectar el hueco aunque el proceso haya muerto.
- **Lógica separada de Crashlytics** (`DiagnosticoGps` + interfaz `ReporteDiagnostico`),
  para probarla con un reportero falso.
- Umbral de hueco: 2 min (4 ciclos de 30 s). Racha de fallas: 5 ciclos (2,5 min).

## Fuera de alcance

- Alertas en tiempo real (Crashlytics puede demorar el envío de no fatales).
- Cambiar el mecanismo del timer por el flujo de posiciones nativo: se decide con los
  datos que junte este diagnóstico.
