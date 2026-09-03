import 'package:flutter/material.dart';

import '../model/clientes_model.dart';
import '../model/producto_model.dart';
import '../model/rutas_model.dart';
import '../model/venta_model.dart';
import '../page/cliente/clientes.page.dart';
import '../page/config/cambiar_clave.page.dart';
import '../page/config/preferences.page.dart';
import '../page/home/home.page.dart';
// --- IMPORTS DE TUS PÁGINAS ---
import '../page/login/login.page.dart'; // O AuthGate si usas ese
import '../page/login/olvide_clave.page.dart';
import '../page/login/cambiar_clave_obligatorio.page.dart';
import '../log/console_log.page.dart';
import '../page/producto/productos.page.dart';
import '../page/rutas/rutas.page.dart';
import '../page/ventas/listado.de.ventas.page.dart';
import '../page/ventas/listado.detalle.de.una.venta.dart';
import '../page/ventas/listado.ultima.venta.page.dart';
import '../page/ventas/venta.encabezado.edicion.page.dart';
import '../page/ventas/venta.item.detalle.edicion.dart';
import 'app_routes.dart';

class AppRouter {

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {

    // --- RUTAS DE ENTRADA ---
      case 'home': // Asegúrate de tener esta constante o usar string
        return MaterialPageRoute(builder: (_) =>  const HomePage());

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(
            sinRutasAsignadas: args is Map<String, dynamic>
                ? (args['sinRutasAsignadas'] as bool? ?? false)
                : false,
          ),
        );

    // --- RUTAS PRINCIPALES (Si se navegaran directamente) ---
      case AppRoutes.listadoVentas:
        return MaterialPageRoute(builder: (_) => const ListadeDeVentasPage());

    // --- PANTALLAS SECUNDARIAS ---
      case AppRoutes.rutas:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => RutasPage(
              multiSelect: args['multiSelect'] as bool? ?? false,
              seleccionInicial:
                  (args['seleccionInicial'] as List<RutasModel>?) ?? const [],
              obligatorio: args['obligatorio'] as bool? ?? false,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const RutasPage());

      case AppRoutes.productosSeleccion:
        return MaterialPageRoute<ProductosModel?>(builder: (_) => const ProductosPage(isForSelection: true));

      case AppRoutes.clientesSeleccion:
        return MaterialPageRoute<ClientesModel?>(builder: (_) => const ClientesPage(isForSelection: true));

    // --- RUTAS CON ARGUMENTOS (Lógica movida desde tu Home) ---

      case AppRoutes.nuevaVenta:
        return MaterialPageRoute(builder: (_) => const VentaEncabezadoEdicionPage());

      case AppRoutes.modificarVenta:
        if (args is Map<String, dynamic>) {
          final venta = args['ventaEnEdicion'] as VentaModel?;
          return MaterialPageRoute(
              builder: (_) => VentaEncabezadoEdicionPage(ventaEnEdicion: venta)
          );
        }
        return _errorRoute("Faltan argumentos en Modificar Venta");

      case AppRoutes.ventaDetalle:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ListadoDetalleDeUnaVentaPage(
              ventaModel: args['ventaModel'],
              esEdicion: args['esEdicion'],
            ),
          );
        }
        return _errorRoute("Faltan argumentos en Venta Detalle");

      case AppRoutes.ventaItemEdicion:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => VentaEdicionItemDetalle(
              actualVenta: args['actualVenta'],
              actualVentaDetalle: args['actualVentaDetalle'],
            ),
          );
        }
        return _errorRoute("Faltan argumentos en Item Edición");

      case AppRoutes.listadoUltimaVenta:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
              builder: (_) => ListadoDetalleDeUltimaVentaPage(ventaModel: args['ventaModel'])
          );
        }
        return _errorRoute("Faltan argumentos en Última Venta");
        
      case AppRoutes.config:
        return MaterialPageRoute(builder: (_) => const ConfiguracionPage());

      case AppRoutes.cambiarClave:
        return MaterialPageRoute(builder: (_) => const CambiarClavePage());

      case AppRoutes.olvideClave:
        return MaterialPageRoute(builder: (_) => const OlvideClavePage());

      case AppRoutes.cambiarClaveObligatorio:
        if (args is Map<String, dynamic> && args['claveActual'] is String) {
          return MaterialPageRoute(
              builder: (_) => CambiarClaveObligatorioPage(claveActual: args['claveActual']));
        }
        return _errorRoute("Faltan argumentos en Cambiar Clave Obligatorio");

      case AppRoutes.consoleLog:
        return MaterialPageRoute(builder: (_) => ConsoleLogPage());

    // DEFAULT
      default:
        return _errorRoute("Ruta no definida: ${settings.name}");
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: const Text("Error de Navegación")),
      body: Center(child: Text(message)),
    ));
  }
}