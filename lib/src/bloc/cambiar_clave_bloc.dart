import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'login_validacion.dart';

class CambiarClaveBloc with Validators {
  final _claveActualController = BehaviorSubject<String>.seeded('');
  final _claveNuevaController = BehaviorSubject<String>.seeded('');
  final _confirmarClaveController = BehaviorSubject<String>.seeded('');

  Stream<String> get claveActualStream =>
      _claveActualController.stream.transform(validarClaveActual).distinct();
  Stream<String> get claveNuevaStream =>
      _claveNuevaController.stream.transform(validarClaveNueva).distinct();

  // La confirmación depende de la clave nueva, por eso se valida cruzando
  // ambos streams en vez de con un StreamTransformer de un solo campo.
  Stream<String> get confirmarClaveStream => Rx.combineLatest2(
        _claveNuevaController.stream,
        _confirmarClaveController.stream,
        (String nueva, String confirmacion) {
          if (confirmacion.isEmpty) {
            throw 'Confirme la clave nueva.';
          }
          if (nueva != confirmacion) {
            throw 'Las claves no coinciden.';
          }
          return confirmacion;
        },
      ).distinct();

  Stream<bool> get formValidStream => Rx.combineLatest3(
      claveActualStream, claveNuevaStream, confirmarClaveStream, (a, b, c) => true);

  Function(String) get changeClaveActual => _claveActualController.sink.add;
  Function(String) get changeClaveNueva => _claveNuevaController.sink.add;
  Function(String) get changeConfirmarClave => _confirmarClaveController.sink.add;

  String get claveActual => _claveActualController.value;
  String get claveNueva => _claveNuevaController.value;

  dispose() {
    _claveActualController.close();
    _claveNuevaController.close();
    _confirmarClaveController.close();
  }
}
