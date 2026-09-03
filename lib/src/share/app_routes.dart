// routes.dart
class AppRoutes {
  static const String listadoVentas = 'listadoDeVentas'; // ListadoDeVentasPage
  static const String productos = 'productos'; // ProductosPage
  static const String productosSeleccion =
      'productosSeleccion'; // ProductosPage(isForSelection)
  static const String clientes = 'clientes'; // ClientesPage
  static const String clientesSeleccion =
      'clientesSeleccion'; // ClientesPage(isForSelection)
  static const String config = 'config'; // ConfiguracionPage
  static const String rutas = 'rutas'; // RutasPage
  static const String nuevaVenta =
      'nuevaVenta'; // VentaEncabezadoEdicionPage(ventaEnEdicion?)
  static const String modificarVenta =
      'modificarVenta'; // VentaEncabezadoEdicionPage(ventaEnEdicion?)
  static const String ventaDetalle =
      'ventaDetalle'; // ListadoDetalleDeUnaVentaPage(ventaModel, esEdicion)
  static const String ventaItemEdicion =
      'ventaItemEdicion'; // VentaEdicionItemDetalle(actualVenta, actualVentaDetalle)
  static const String login = 'login'; // LoginPage
  static const String cambiarClave = 'cambiarClave'; // CambiarClavePage
  static const String cambiarClaveObligatorio =
      'cambiarClaveObligatorio'; // CambiarClaveObligatorioPage
  static const String olvideClave = 'olvideClave'; // OlvideClavePage
  static const String home = 'home'; // ListadeDeVentasPage
  static const String listadoUltimaVenta =
      'listadoUltimaVenta'; // ListadoDetalleDeUltimaVentaPage'
  static const String consoleLog = 'consoleLog'; // ConsoleLogPage
}
