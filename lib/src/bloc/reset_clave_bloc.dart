import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'login_validacion.dart';

class ResetClaveBloc with Validators {
  final _codigoController = BehaviorSubject<String>.seeded('');
  final _claveNuevaController = BehaviorSubject<String>.seeded('');
  final _confirmarClaveController = BehaviorSubject<String>.seeded('');

  Stream<String> get codigoStream =>
      _codigoController.stream.transform(validarCodigoRecuperacion).distinct();
  Stream<String> get claveNuevaStream =>
      _claveNuevaController.stream.transform(validarClaveNueva).distinct();

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
      codigoStream, claveNuevaStream, confirmarClaveStream, (a, b, c) => true);

  Function(String) get changeCodigo => _codigoController.sink.add;
  Function(String) get changeClaveNueva => _claveNuevaController.sink.add;
  Function(String) get changeConfirmarClave => _confirmarClaveController.sink.add;

  String get codigo => _codigoController.value;
  String get claveNueva => _claveNuevaController.value;

  dispose() {
    _codigoController.close();
    _claveNuevaController.close();
    _confirmarClaveController.close();
  }
}
