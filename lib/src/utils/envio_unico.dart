/// Evita que un botón dispare dos veces la misma acción asíncrona (por ejemplo
/// dos toques en "Detalle Venta" creando dos ventas): mientras [ejecutar] está
/// en curso, las llamadas siguientes se ignoran.
class EnvioUnico {
  final void Function(bool enCurso)? _alCambiar;
  bool _enCurso = false;

  EnvioUnico({void Function(bool enCurso)? alCambiar}) : _alCambiar = alCambiar;

  bool get enCurso => _enCurso;

  Future<void> ejecutar(Future<void> Function() accion) async {
    if (_enCurso) return;
    _cambiar(true);
    try {
      await accion();
    } finally {
      _cambiar(false);
    }
  }

  void _cambiar(bool valor) {
    _enCurso = valor;
    _alCambiar?.call(valor);
  }
}
