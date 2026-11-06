# Vista "Meta" del vendedor (app móvil) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar al drawer una opción "Meta" para que el vendedor vea cuánto lleva vendido este mes contra su meta. La pantalla muestra un gauge semicircular, las cifras en grande y dos gráficos de barras: las ventas del mes por día y los últimos 12 meses.

**Architecture:**
- `MetaProvider` consume `GET /api/metas/mia` con `ApiClient().dio`, igual que los otros providers.
- El JSON se mapea a `TableroMetaModel`.
- `MetaPage` es un `StatefulWidget` con un `Future`, igual que `ResumenDeVentasPage`. Dibuja el gauge con `CustomPainter` y los gráficos con `fl_chart`.
- La app no calcula nada de negocio: solo muestra lo que entrega el server.

**Tech Stack:**
- Flutter 3.44, Dio 5 e intl (`es_CL`).
- `fl_chart` es la única dependencia nueva. Va en la última versión estable compatible, que es la que resuelva `flutter pub add fl_chart`.
- Pruebas con `flutter_test` y `mocktail`.

**Spec:** `/Users/cursor/Dev/dipalza/application_v2.0/dipalza_server/docs/superpowers/specs/2026-11-05-metas-vendedor-design.md`, sección "### 8. Vista Meta en la app móvil". El contrato de la API está en la sección 6; el server ya está implementado en la rama `feat/metas-vendedor`.

## Global Constraints

- **Contrato `GET /api/metas/mia`.** Exige un usuario autenticado; el vendedor sale del token y nunca se envía como parámetro. Respuestas:
  - `200`, con este cuerpo:
    ```json
    {
      "periodo": "2026-11",
      "calculadoEn": "2026-11-06T15:30:00.123-03:00",
      "meta": 35751000 | null,
      "vendido": 1234567,
      "avance": 3.5 | null,
      "cantidadVentas": 4,
      "diario": [{ "fecha": "2026-11-01", "vendido": 0 }, ...],
      "mensual": [{ "periodo": "2025-12", "vendido": 0, "meta": null }, ...]
    }
    ```
    `diario` trae todos los días del mes en curso. `mensual` trae exactamente 12 meses y el último es el mes en curso. Los números pueden llegar como `int` o como `double`, así que se leen con `(json[...] as num?)?.toDouble()`.
  - `404 {"message": "El usuario no tiene un vendedor asociado."}`
  - `401/403`: los maneja `ApiClient`, que renueva el token o cierra la sesión.
- **"Sin meta"** es `meta == null || meta <= 0`, o bien `avance == null`. En ese caso:
  - no se dibuja el gauge;
  - se muestran el vendido y los gráficos, con el texto **"Sin meta asignada este mes"**.
  - La app **nunca divide** para calcular el avance; usa el `avance` del server.
- **Cifras en grande:**
  - **Vendido**, **Meta**, **Avance** (`61,7 %`, con 1 decimal) y **Falta**.
  - Falta es `meta - vendido` cuando es mayor que 0. Si vendido ≥ meta, en su lugar va **"¡Meta cumplida!"**.
  - Los montos van con `getValorModena(valor, 0)` de `lib/src/utils/utils.dart`, con el formato `$12.345.678`.
- **Gauge:** semicircular, con un arco de 180°. Se satura visualmente en 100 %, pero el texto muestra el porcentaje real aunque pase de 100 (`125,0 %`).
- **Debajo del gauge:**
  - el mes con su año, por ejemplo "Noviembre 2026" (`DateFormat('MMMM y', 'es_CL')`, con la primera letra en mayúscula);
  - "N ventas cerradas";
  - "Actualizado a las HH:mm", tomado de `calculadoEn`;
  - la nota **"Se cuentan las ventas transferidas, sin flete, según su fecha de facturación."**
- **Gráficos de barras (`fl_chart`):**
  - **Ventas del mes:** una barra por día con el vendido. Si hay meta, se agrega una línea horizontal de meta diaria promedio, igual a la meta dividida por los días del mes. Esa es la única división de la app; es de presentación y está documentada en código.
  - **Últimos 12 meses:** una barra por mes con el vendido. Si la meta del mes es > 0, se dibuja una marca de la meta sobre la barra con `BarChartRodStackItem`, o como barra fantasma detrás. Si es null o ≤ 0, no hay marca. Las etiquetas usan la inicial del mes en 3 letras ("dic", "ene"…) y el mes en curso se resalta.
- **Estados:**
  - **carga:** `CircularProgressIndicator`;
  - **error:** el texto "No se pudo cargar tu meta." y un botón "Reintentar";
  - **404:** el mensaje del server, sin botón de reintento.
- **Refresco:** la página se carga al abrirse (`initState`) y con pull-to-refresh (`RefreshIndicator`). No se cachea nada.
- **Drawer:** un `ListTile` "Meta" con `Icons.flag`, puesto después de "Clientes" y antes del `Divider`. La página va en `_pages` de `home.page.dart`, en la posición que corresponda, y se ajustan los índices de "Configuración". El AppBar sigue el patrón de `ResumenDeVentasPage`: `colorRojoBase()`, botón de menú que abre el drawer con `AppScaffoldKey.homeKey` y título "Meta".
- **Convenciones:**
  - nombres en español;
  - `dart analyze` sin errores nuevos (complejidad ciclomática ≤ 20 y anidamiento ≤ 5);
  - los widgets grandes se dividen en archivos dentro de `lib/src/page/meta/`.
- **Comandos:**
  - pruebas: `flutter test`, o `flutter test <archivo>` para correr uno;
  - análisis: `dart analyze`.
- **Rama:** `feat/vista-meta`, creada desde `origin/main`. Los commits terminan con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No se hace push.

## Review Focus

1. **Vendedor sin meta.** No hay gauge ni división, aparece el texto "Sin meta asignada este mes" y los gráficos igual se muestran. Lo cubre `metaPage_sinMeta_muestraTextoYSinGauge` (Task 2).
2. **Meta superada.** El gauge queda lleno, el texto dice `125,0 %` y aparece "¡Meta cumplida!" en vez de un Falta negativo. Lo cubre `metaPage_metaSuperada_muestraCumplida` (Task 2).
3. **Usuario sin vendedor (404).** Se muestra el mensaje del server, sin reintento ni pantalla rota. Lo cubre `metaProvider_404_lanzaSinVendedor` (Task 1) junto con `metaPage_sinVendedor_muestraMensaje` (Task 2).
4. **JSON con montos enteros o decimales, y metas null en `mensual`.** No debe caerse por casteo. Lo cubre `tableroMeta_fromJson_numerosIntYDoubleYNull` (Task 1).
5. **Mes de 12 meses con meta 0.** No se dibuja la marca de meta. Lo cubre `graficoMensual_metaCero_sinMarca` (Task 3).

---

### Task 1: Modelo y `MetaProvider`

**Files:**
- Create: `lib/src/model/tablero_meta_model.dart`
- Create: `lib/src/provider/meta_provider.dart`
- Test: `test/unit/tablero_meta_model_test.dart`, `test/unit/meta_provider_test.dart`

**Interfaces:**
- Produces:
  - `class VendidoDiaModel { final DateTime fecha; final double vendido; }`
  - `class VendidoMesModel { final String periodo; final double vendido; final double? meta; }`
  - `class TableroMetaModel { final String periodo; final DateTime calculadoEn; final double? meta; final double vendido; final double? avance; final int cantidadVentas; final List<VendidoDiaModel> diario; final List<VendidoMesModel> mensual; bool get tieneMeta; factory TableroMetaModel.fromJson(Map<String, dynamic>); }`
    - `tieneMeta` es `meta != null && meta! > 0 && avance != null`.
    - `fecha` se parsea como fecha local (`DateTime.parse('2026-11-03')`).
  - `class MetaSinVendedorException implements Exception { final String mensaje; }`
  - `class MetaProvider`:
    - `MetaProvider({Dio? dio})`, que usa `ApiClient().dio` por defecto. Así se puede inyectar un mock en las pruebas.
    - `static final MetaProvider metaProvider = MetaProvider();`
    - `Future<TableroMetaModel> obtenerMiMeta()`, que hace un GET a `/api/metas/mia`. Un 404 lanza `MetaSinVendedorException(message)`; cualquier otro error relanza la `DioException` original.

- [ ] **Step 1: Write the failing tests.**
  - `tableroMeta_fromJson_numerosIntYDoubleYNull`: mezcla `vendido: 150000` (int) con `meta: 35751000.0` (double); `avance: null`; una entrada de `mensual` con `meta: null`. Todo se lee sin excepciones y los valores coinciden.
  - `tableroMeta_tieneMeta`: `meta` null → false; `0` → false; `>0` con `avance` null → false; `>0` con `avance` 61.7 → true.
  - `metaProvider_ok_mapeaRespuesta`: con un `Dio` mock de mocktail, `get('/api/metas/mia')` devuelve un `Response` 200 con el JSON; `obtenerMiMeta()` entrega `periodo == '2026-11'`.
  - `metaProvider_404_lanzaSinVendedor`: una `DioException` con response 404 y `{"message": "El usuario no tiene un vendedor asociado."}` → `throwsA(isA<MetaSinVendedorException>())` con ese mensaje.
  - `metaProvider_500_relanzaDioException`.
- [ ] **Step 2: Run** `flutter test test/unit/tablero_meta_model_test.dart test/unit/meta_provider_test.dart`. Expected: no compila.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** el mismo comando. Expected: PASS.
- [ ] **Step 5: Commit** `feat: modelo y provider de la meta del vendedor`.

### Task 2: Página `MetaPage` con gauge y cifras, más la entrada del drawer

**Files:**
- Create: `lib/src/page/meta/meta.page.dart`, `lib/src/page/meta/gauge_meta.dart` (el `CustomPainter` y su widget), `lib/src/page/meta/formato_meta.dart` (funciones puras)
- Modify: `lib/src/page/home/home.page.dart` (los imports, `_pages` y el `ListTile` "Meta")
- Test: `test/unit/formato_meta_test.dart`, `test/widget/meta_page_test.dart`

**Interfaces:**
- Consumes: `TableroMetaModel`, `MetaProvider` y `MetaSinVendedorException` (Task 1).
- Produces:
  - `formato_meta.dart`:
    - `String formatearAvance(double? avance)` → `"61,7 %"`, o `"Sin meta"` si es null;
    - `double fraccionGauge(double? avance)` → valor entre 0 y 1, saturado, y 0 si es null;
    - `String? textoFalta(TableroMetaModel t)` → `"$1.234.567"`, o null si no hay meta;
    - `bool metaCumplida(TableroMetaModel t)`;
    - `String nombreMes(String periodo)` → `"Noviembre 2026"`.
  - `class MetaPage extends StatefulWidget { const MetaPage({super.key, MetaProvider? provider}); }`. El provider se puede inyectar para las pruebas.
  - `class GaugeMeta extends StatelessWidget { const GaugeMeta({required double fraccion, required String texto}); }`

- [ ] **Step 1: Write the failing tests.**
  - `formato_meta_test.dart`:
    - `formatearAvance(61.7)` → `'61,7 %'`; `formatearAvance(125)` → `'125,0 %'`; `formatearAvance(null)` → `'Sin meta'`;
    - `fraccionGauge(125)` → `1.0`; `fraccionGauge(null)` → `0`;
    - `textoFalta` con meta 1.000.000 y vendido 400.000 → `'$600.000'`;
    - `metaCumplida` con vendido ≥ meta → true;
    - `nombreMes('2026-11')` → `'Noviembre 2026'`.
  - `meta_page_test.dart`, con un `MetaProvider` mock de mocktail:
    - `metaPage_conMeta_muestraCifrasYGauge`: aparecen el vendido, la meta, `'61,7 %'`, el Falta y `find.byType(GaugeMeta)`.
    - `metaPage_sinMeta_muestraTextoYSinGauge`: aparece `'Sin meta asignada este mes'` y `find.byType(GaugeMeta)` → `findsNothing`.
    - `metaPage_metaSuperada_muestraCumplida`: aparecen `'125,0 %'` y `'¡Meta cumplida!'`, y no hay ningún Falta.
    - `metaPage_sinVendedor_muestraMensaje`: el provider lanza `MetaSinVendedorException('El usuario no tiene un vendedor asociado.')`; se ve ese texto y no hay botón "Reintentar".
    - `metaPage_error_reintenta`: el provider lanza una excepción genérica; se ve "No se pudo cargar tu meta."; un tap en "Reintentar" llama al provider dos veces.
    - `metaPage_muestraNota`: aparece el texto exacto de la nota.
- [ ] **Step 2: Run** `flutter test test/unit/formato_meta_test.dart test/widget/meta_page_test.dart`. Expected: no compila.
- [ ] **Step 3: Implement.**
  - Agregar `MetaPage()` a `_pages` y el `ListTile` "Meta" con `Icons.flag` después de "Clientes".
  - Ajustar los índices de "Configuración" y sus `selected`.
  - En las pruebas de widget, inicializar `es_CL` con `initializeDateFormatting('es_CL')`.
- [ ] **Step 4: Run** el mismo comando, después `flutter test` (la suite completa) y `dart analyze`. Expected: PASS, sin errores nuevos.
- [ ] **Step 5: Commit** `feat: vista Meta del vendedor con gauge y cifras del mes`.

### Task 3: Gráficos de barras con `fl_chart`

**Files:**
- Modify: `pubspec.yaml` (agregar `fl_chart` con `flutter pub add fl_chart`)
- Create: `lib/src/page/meta/graficos_meta.dart` (los widgets `GraficoDiarioMeta` y `GraficoMensualMeta`, más las funciones puras que arman los datos)
- Modify: `lib/src/page/meta/meta.page.dart` (los dos gráficos van bajo las cifras, con un título cada uno: "Ventas del mes" y "Últimos 12 meses")
- Test: `test/unit/graficos_meta_test.dart`, y ampliar `test/widget/meta_page_test.dart`

**Interfaces:**
- Consumes: `TableroMetaModel` (Task 1) y `MetaPage` (Task 2).
- Produces:
  - `List<BarChartGroupData> gruposDiarios(TableroMetaModel t)`: un grupo por día, con `x` = día del mes.
  - `double? metaDiariaPromedio(TableroMetaModel t)`: `meta / diario.length` si `tieneMeta`, o null en otro caso. Es la única división, y es solo de presentación.
  - `List<BarChartGroupData> gruposMensuales(TableroMetaModel t)`: 12 grupos. Cada grupo trae el vendido y, si la `meta` del mes es > 0, la marca de meta.
  - `String etiquetaMes(String periodo)`: `"dic"`, `"ene"`…, en minúscula y sin punto.
  - `GraficoDiarioMeta({required TableroMetaModel tablero})` y `GraficoMensualMeta({required TableroMetaModel tablero})`.

- [ ] **Step 1: Write the failing tests.**
  - `graficos_meta_test.dart`:
    - `gruposDiarios_unGrupoPorDia`: con 30 días salen 30 grupos, y el día 3 tiene el vendido correcto.
    - `metaDiariaPromedio_sinMeta_null`.
    - `metaDiariaPromedio_conMeta`: meta 30.000.000 en 30 días → 1.000.000.
    - `gruposMensuales_doce`.
    - `graficoMensual_metaCero_sinMarca`: un mes con meta 0 y otro con meta null no llevan marca, y uno con meta > 0 sí la lleva.
    - `etiquetaMes('2025-12')` → `'dic'`.
  - `meta_page_test.dart`:
    - `metaPage_muestraAmbosGraficos`: aparecen `find.byType(GraficoDiarioMeta)`, `find.byType(GraficoMensualMeta)` y los títulos.
- [ ] **Step 2: Run** `flutter test test/unit/graficos_meta_test.dart test/widget/meta_page_test.dart`. Expected: no compila.
- [ ] **Step 3: Implement.**
  - Usar `BarChart` de `fl_chart`.
  - La meta diaria va como `ExtraLinesData(horizontalLines: [HorizontalLine(y: ...)])`.
  - Los tooltips de las barras usan `getValorModena`.
- [ ] **Step 4: Run** `flutter test` (la suite completa) y `dart analyze`. Expected: PASS, sin errores nuevos.
- [ ] **Step 5: Verificar en vivo** (lo hace el usuario). Correr la app contra el server local de la rama `feat/metas-vendedor`, con un usuario vendedor, abrir "Meta" en el drawer y comparar con `curl /api/metas/mia`.
- [ ] **Step 6: Commit** `feat: gráficos de ventas del mes y de 12 meses en la vista Meta`.
