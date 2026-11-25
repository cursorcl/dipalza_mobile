import 'package:dipalza_movil/src/services/connectivity_service.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Llama a [alVolverConexion] cuando el server vuelve a estar en línea después
/// de haber estado inalcanzable (sin señal), para que la pantalla recargue lo
/// que no pudo cargar sin que el vendedor tenga que salir y volver a entrar.
mixin RecargaAlVolverConexion<T extends StatefulWidget> on State<T> {
  ConnectivityService? _conexion;
  ServerStatus? _estado;

  void alVolverConexion();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ConnectivityService? conexion;
    try {
      conexion = Provider.of<ConnectivityService>(context, listen: false);
    } on ProviderNotFoundException {
      conexion = null; // Pantalla montada sin el provider (tests).
    }
    if (identical(conexion, _conexion)) return;
    _conexion?.removeListener(_alCambiarEstado);
    _conexion = conexion;
    _estado = conexion?.status;
    conexion?.addListener(_alCambiarEstado);
  }

  void _alCambiarEstado() {
    final anterior = _estado;
    final actual = _conexion!.status;
    _estado = actual;
    final volvio = actual == ServerStatus.online &&
        (anterior == ServerStatus.offline || anterior == ServerStatus.noInternet);
    if (volvio && mounted) alVolverConexion();
  }

  @override
  void dispose() {
    _conexion?.removeListener(_alCambiarEstado);
    super.dispose();
  }
}
