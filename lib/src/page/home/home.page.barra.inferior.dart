// ignore_for_file: unused_import

import 'package:dipalza_movil/src/page/login/login.page.dart';
import 'package:dipalza_movil/src/page/ventas/listado.ultima.venta.page.dart';
import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:flutter/material.dart';

import '../../model/venta_model.dart';
import '../cliente/clientes.page.dart';
import '../config/preferences.page.dart';
import '../producto/productos.page.dart';
import '../rutas/rutas.page.dart';
import '../ventas/listado.de.ventas.page.dart';
import '../ventas/listado.detalle.de.una.venta.dart';
import '../ventas/venta.encabezado.edicion.page.dart';
import '../ventas/venta.item.detalle.edicion.dart';

class HomePageBarraInferior extends StatefulWidget {
  const HomePageBarraInferior({super.key});

  @override
  State<HomePageBarraInferior> createState() => _HomePageBarraInferiorState();
}

class _HomePageBarraInferiorState extends State<HomePageBarraInferior> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const ListadeDeVentasPage(),
    const ProductosPage(),
    const ClientesPage(),
    const ConfiguracionPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final salir = await _confirmarSalida(context);
          if (salir ?? false) {
            // Si confirma salir, cerramos la app
            if (context.mounted) Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) {
              setState(() => _currentIndex = i);
            },
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.shopping_cart), label: 'Ventas'),
              NavigationDestination(
                  icon: Icon(Icons.inventory_2), label: 'Productos'),
              NavigationDestination(
                  icon: Icon(Icons.person), label: 'Clientes'),
              NavigationDestination(
                  icon: Icon(Icons.settings), label: 'Config'),
            ],
          ),
        ));
  }

  Future<bool?> _confirmarSalida(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar salida'),
        content:
            const Text('¿Desea cerrar la sesión y salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => AppNavigator.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => AppNavigator.pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
