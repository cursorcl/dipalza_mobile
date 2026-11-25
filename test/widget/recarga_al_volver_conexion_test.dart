import 'package:dipalza_movil/src/services/connectivity_service.dart';
import 'package:dipalza_movil/src/widget/recarga_al_volver_conexion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Pantalla extends StatefulWidget {
  final VoidCallback alRecargar;
  const _Pantalla(this.alRecargar);

  @override
  State<_Pantalla> createState() => _PantallaState();
}

class _PantallaState extends State<_Pantalla> with RecargaAlVolverConexion {
  @override
  void alVolverConexion() => widget.alRecargar();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  Future<ConnectivityService> montar(WidgetTester tester, VoidCallback alRecargar) async {
    final conexion = ConnectivityService();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: conexion,
      child: MaterialApp(home: _Pantalla(alRecargar)),
    ));
    return conexion;
  }

  testWidgets('recarga cuando el server vuelve tras estar sin conexión', (tester) async {
    var recargas = 0;
    final conexion = await montar(tester, () => recargas++);

    conexion.fijarEstado(ServerStatus.noInternet);
    conexion.fijarEstado(ServerStatus.online);

    expect(recargas, 1);
  });

  testWidgets('no recarga en el primer "en línea" del arranque', (tester) async {
    var recargas = 0;
    final conexion = await montar(tester, () => recargas++);

    conexion.fijarEstado(ServerStatus.online);

    expect(recargas, 0);
  });
}
