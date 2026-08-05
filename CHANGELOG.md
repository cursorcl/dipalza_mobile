## [2.6.1](https://github.com/cursorcl/dipalza_mobile/compare/v2.6.0...v2.6.1) (2026-08-05)


### Bug Fixes

* renombra dipalza.apk a dipalza-app.apk en el script remoto ([#20](https://github.com/cursorcl/dipalza_mobile/issues/20)) ([420baa6](https://github.com/cursorcl/dipalza_mobile/commit/420baa6a5749a91fc0ad514838a9c2e23ec1bb0e))

# [2.6.0](https://github.com/cursorcl/dipalza_mobile/compare/v2.5.2...v2.6.0) (2026-08-05)


### Features

* agrega deploy manual del APK al servidor propio ([#19](https://github.com/cursorcl/dipalza_mobile/issues/19)) ([e285836](https://github.com/cursorcl/dipalza_mobile/commit/e285836e16b5b9cd0bbf52fa68523a71e7510e46))

## [2.5.2](https://github.com/cursorcl/dipalza_mobile/compare/v2.5.1...v2.5.2) (2026-08-05)


### Bug Fixes

* permite cerrar el teclado tocando fuera o con scroll en edición de item ([#18](https://github.com/cursorcl/dipalza_mobile/issues/18)) ([591cc17](https://github.com/cursorcl/dipalza_mobile/commit/591cc176806060ccd2a2cd53a7b58a83ca33e064))

## [2.5.1](https://github.com/cursorcl/dipalza_mobile/compare/v2.5.0...v2.5.1) (2026-08-05)


### Bug Fixes

* corrige navegación y mensaje vacío en selección de cliente para venta ([#17](https://github.com/cursorcl/dipalza_mobile/issues/17)) ([b1b954b](https://github.com/cursorcl/dipalza_mobile/commit/b1b954b9daac291ae6fcdb0e7d9569f2a8375b61))

# [2.5.0](https://github.com/cursorcl/dipalza_mobile/compare/v2.4.1...v2.5.0) (2026-08-04)


### Features

* botón Siguiente en teclado numérico de Cantidad y Descuento ([#16](https://github.com/cursorcl/dipalza_mobile/issues/16)) ([043132d](https://github.com/cursorcl/dipalza_mobile/commit/043132d51f350a290306b248c78fa153c8439ca1))

## [2.4.1](https://github.com/cursorcl/dipalza_mobile/compare/v2.4.0...v2.4.1) (2026-07-23)


### Bug Fixes

* mejora confiabilidad del reporte de posición GPS y permisos de ubicación ([#13](https://github.com/cursorcl/dipalza_mobile/issues/13)) ([871a044](https://github.com/cursorcl/dipalza_mobile/commit/871a044254423d369826ea1913ea006e3b771b43))
* renombra la app a "Ventas" en pantalla de inicio ([#14](https://github.com/cursorcl/dipalza_mobile/issues/14)) ([4506967](https://github.com/cursorcl/dipalza_mobile/commit/45069678ac3c861fcc8f6d05d9ccdc405a71658d))

# [2.4.0](https://github.com/cursorcl/dipalza_mobile/compare/v2.3.0...v2.4.0) (2026-07-19)


### Features

* unifica estilo del botón Guardar con Finalizar ([#12](https://github.com/cursorcl/dipalza_mobile/issues/12)) ([be775f8](https://github.com/cursorcl/dipalza_mobile/commit/be775f83cd05408fdd7916e3f22d35f9e4125904))

# [2.3.0](https://github.com/cursorcl/dipalza_mobile/compare/v2.2.0...v2.3.0) (2026-07-19)


### Features

* muestra monto calculado de ILA en detalle de venta ([#11](https://github.com/cursorcl/dipalza_mobile/issues/11)) ([cc1aab3](https://github.com/cursorcl/dipalza_mobile/commit/cc1aab3ecbdde966f72731825784a187210b95fa))

# [2.2.0](https://github.com/cursorcl/dipalza_mobile/compare/v2.1.0...v2.2.0) (2026-07-19)


### Bug Fixes

* **ci:** usa PAT admin en checkout para permitir push de versión a main ([#10](https://github.com/cursorcl/dipalza_mobile/issues/10)) ([cbbfbc6](https://github.com/cursorcl/dipalza_mobile/commit/cbbfbc6193948ecaa4f6ddfef0a2e56584c17cfa))


### Features

* diferencia visualmente Precio 1 y Precio 2 en edición de detalle de venta ([#9](https://github.com/cursorcl/dipalza_mobile/issues/9)) ([5d1584e](https://github.com/cursorcl/dipalza_mobile/commit/5d1584e820a6ed90800ebf6967ea1abd6c48a588))

# Changelog

## [2.1.0](https://github.com/cursorcl/dipalza_mobile/compare/v2.0.1...v2.1.0) (2026-07-18)


### Features

* agrega caché TTL a ProductsBloc y migra ProductosPage a ensureFresh/forceRefresh ([b2a2a73](https://github.com/cursorcl/dipalza_mobile/commit/b2a2a73d905ad4536b7b0f3332d77ced3e977370))
* agrega CachedListStore para persistir listas con TTL ([ce40ff8](https://github.com/cursorcl/dipalza_mobile/commit/ce40ff88cb9816449be0f6317e72e2edda993348))
* agrega ClientesBloc con caché TTL y migra ClientesPage a StreamBuilder ([8ac54e8](https://github.com/cursorcl/dipalza_mobile/commit/8ac54e8aef40979e920e0fe6a40719b19dfe7162))
* agrega manejo de errores y reintento en carga de detalle de venta ([9edddd0](https://github.com/cursorcl/dipalza_mobile/commit/9edddd0578956e88244573e24dab6ed98f57dd59))
* agrega Resumen de Venta al menú lateral de la app móvil ([0d739db](https://github.com/cursorcl/dipalza_mobile/commit/0d739db94dceddcee3f4b043dd8b0607fb9fba09))
* agrega ResumenVentasCalculator con totales agregados de ventas ([cab33be](https://github.com/cursorcl/dipalza_mobile/commit/cab33be03235809eb05dfc42a5c72522e8f657fd))
* agrega Últimas Ventas al menú lateral ([ad73a92](https://github.com/cursorcl/dipalza_mobile/commit/ad73a92655e67942128dd233868208500e8621cc))
* agrega UltimasVentasClientePage ([f2648c3](https://github.com/cursorcl/dipalza_mobile/commit/f2648c32fe2550dfd417d2135555c2927c9a4cf7))
* agrega VendedorRutaProvider y caché local de rutas asignadas ([7a92527](https://github.com/cursorcl/dipalza_mobile/commit/7a925270e260768a27a6107873380c62c29ce678))
* agrega VentaProvider.obtenerUltimasVentasDeCliente ([e90c0ed](https://github.com/cursorcl/dipalza_mobile/commit/e90c0edab9a1362234571276f40ec7699861b53f))
* agrega VentaProvider.obtenerVentasPendientesFacturacion() y ResumenDeVentasPage ([a16358c](https://github.com/cursorcl/dipalza_mobile/commit/a16358c33365d7a87268f144df9fb0936e24df39))
* Configuración usa selección múltiple de rutas (chips) ([7804c18](https://github.com/cursorcl/dipalza_mobile/commit/7804c18c5c239496d254269241da44aa56565122))
* login no pide ruta; fuerza selección solo si el vendedor no tiene ninguna ([82c9784](https://github.com/cursorcl/dipalza_mobile/commit/82c978476e65256ed6d06292c19e8c24bf6c391b))
* pide la URL del servidor si no hay ninguna guardada ([5c486fb](https://github.com/cursorcl/dipalza_mobile/commit/5c486fb6fb2cc6f45d9ce21582536686f06c3fa0))
* RutasPage soporta selección múltiple y modo obligatorio ([3d9f0b3](https://github.com/cursorcl/dipalza_mobile/commit/3d9f0b35502409b0922eef869f678520ea77c366))


### Bug Fixes

* agrega Content-Type explícito al guardar rutas asignadas ([002ffe6](https://github.com/cursorcl/dipalza_mobile/commit/002ffe6524c2fad464d715b111566ba296904c3f))
* configura localización en español para DatePicker y widgets de Material ([8a72bb9](https://github.com/cursorcl/dipalza_mobile/commit/8a72bb9dd23ee35bf42f8aeb8e00e635c30611d7))
* corrige round-trip de ClientesModel.toJson/fromJson ([9b856d5](https://github.com/cursorcl/dipalza_mobile/commit/9b856d584dc96ec7765bcc84ea9f4665b18e7bf3))
* diagnóstico claro cuando la respuesta de rutas del vendedor no es una lista ([b831b5d](https://github.com/cursorcl/dipalza_mobile/commit/b831b5d5bc8df0c4509f89ef31f632516ea76580))
* difiere la apertura del selector de cliente hasta después del primer frame ([4324748](https://github.com/cursorcl/dipalza_mobile/commit/432474821c0dce542b48b57d57d2ff4a771a791c))
* evita crash de ApiClient cuando urlServicio está vacío ([0aaee2e](https://github.com/cursorcl/dipalza_mobile/commit/0aaee2eac47273f9db7716854df382b0f1367b97))
* fuerza re-login si la sesión restaurada no tiene 'tipo' guardado ([6e178a4](https://github.com/cursorcl/dipalza_mobile/commit/6e178a48073755f2019738556ee70bbfb8e8f79a))
* lee codigoRuta del backend al mapear ClientesModel ([598269d](https://github.com/cursorcl/dipalza_mobile/commit/598269db6dbff5689650af7028a7631937f84eca))
* obliga selección de rutas también en sesión recuperada por refresh token ([85eb90f](https://github.com/cursorcl/dipalza_mobile/commit/85eb90f3a7a50069f59e3216a797c6b726ede8be))
* providers de clientes y productos propagan errores en vez de devolver lista vacía ([1dc3fe2](https://github.com/cursorcl/dipalza_mobile/commit/1dc3fe2c69e009aa22382f3ec27d059d88de04fd))
* resumen de venta usa el mismo listado que la pantalla Ventas ([471c40f](https://github.com/cursorcl/dipalza_mobile/commit/471c40ff77c2aaf34d503214b827ed4be2d48e0e))
* RutasPage permite reintentar carga y cerrar sesión en modo obligatorio ([0b9d4c6](https://github.com/cursorcl/dipalza_mobile/commit/0b9d4c60b956f10111c4d2d2bfec3e15fa637b9f))
* sincroniza los índices del drawer con el nuevo orden de _pages ([81f451e](https://github.com/cursorcl/dipalza_mobile/commit/81f451e2759ef5edbacf0eb8c662f2d957fc1a59))
* tipa la ruta clientesSeleccion como MaterialPageRoute&lt;ClientesModel?&gt; ([5010316](https://github.com/cursorcl/dipalza_mobile/commit/501031653a6066871486ec90a4691e3871df48bd))
* VendedorRutaProvider propaga errores reales en vez de tragarlos ([b5bdbd9](https://github.com/cursorcl/dipalza_mobile/commit/b5bdbd9d5e59b769c4b60bdf638130fdcdf8178d))
* venta usa la ruta del cliente seleccionado, corrige typo tuta-&gt;ruta ([2d917d9](https://github.com/cursorcl/dipalza_mobile/commit/2d917d934787f339cf70551a4dbeb21e68cefb8e))

## [1.0.1](https://github.com/cursorcl/flutterDipalza/compare/v1.0.0...v1.0.1) (2026-07-12)


### Bug Fixes

* actualiza compileSdk a 36, Gradle a 8.14 y Kotlin a 2.2.20 para compatibilidad con plugins ([3238276](https://github.com/cursorcl/flutterDipalza/commit/3238276f12da30fdba3c3e8658c1a4e954d77501))
* actualiza fluttertoast a ^9.1.0 con soporte para compileSdk 34+ ([82629ea](https://github.com/cursorcl/flutterDipalza/commit/82629ea1d988a6b57991381e06717d9de861a1b1))
* aplica migraciones automáticas de Flutter 3.44.4 a archivos Gradle de Android ([f8baef9](https://github.com/cursorcl/flutterDipalza/commit/f8baef975d90f87abc94bc7d9a206e719531550a))
* corrige configuración Android para build en CI y local ([20a56f3](https://github.com/cursorcl/flutterDipalza/commit/20a56f3aca8f06f3de429c64dbc5a9d93177c3f6))
* corrige login, carga de rutas y servicio de ubicación en iOS ([32cdd49](https://github.com/cursorcl/flutterDipalza/commit/32cdd49d1fae0a321ea417ca1e84b28af763722b))
* elimina sobreescritura de compileSdk en build.gradle raíz incompatible con Gradle 8.14 ([b998d91](https://github.com/cursorcl/flutterDipalza/commit/b998d91fb50bc89183755c2397b9a47c4ef1eab3))
* fuerza compileSdk 36 en plugins usando plugins.withId compatible con AGP 8.x ([a549504](https://github.com/cursorcl/flutterDipalza/commit/a549504dde2d6126d7d104ee4cf74781a5f13de3))

## 1.0.0 (2026-07-01)


### Bug Fixes

* inicio de versionamiento automático ([e5706f7](https://github.com/cursorcl/flutterDipalza/commit/e5706f78dd7a1b82fa6629ab279997bedfe640a1))

## Changelog
