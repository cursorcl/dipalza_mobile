import 'package:dipalza_movil/src/bloc/cambiar_clave_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CambiarClaveBloc bloc;

  setUp(() => bloc = CambiarClaveBloc());
  tearDown(() => bloc.dispose());

  // Los campos se fijan antes de suscribirse al stream derivado: al ser
  // BehaviorSubjects, la suscripción repite el último valor ya asignado
  // como primer (y único) evento, evitando depender del valor semilla ''.

  test('claveActualStream emite error si está vacía', () async {
    bloc.changeClaveActual('');
    await expectLater(bloc.claveActualStream.first, throwsA(isA<String>()));
  });

  test('claveNuevaStream emite error si tiene menos de 8 caracteres', () async {
    bloc.changeClaveNueva('corta1');
    await expectLater(bloc.claveNuevaStream.first, throwsA(isA<String>()));
  });

  test('claveNuevaStream emite el valor si cumple el largo mínimo', () async {
    bloc.changeClaveNueva('claveValida1');
    expect(await bloc.claveNuevaStream.first, 'claveValida1');
  });

  test('confirmarClaveStream emite error si no coincide con la clave nueva', () async {
    bloc.changeClaveNueva('claveValida1');
    bloc.changeConfirmarClave('otraClave1');
    await expectLater(bloc.confirmarClaveStream.first, throwsA(isA<String>()));
  });

  test('confirmarClaveStream emite el valor si coincide con la clave nueva', () async {
    bloc.changeClaveNueva('claveValida1');
    bloc.changeConfirmarClave('claveValida1');
    expect(await bloc.confirmarClaveStream.first, 'claveValida1');
  });

  test('formValidStream solo emite cuando los 3 campos son válidos', () async {
    bloc.changeClaveActual('claveVieja');
    bloc.changeClaveNueva('claveValida1');
    bloc.changeConfirmarClave('claveValida1');

    expect(await bloc.formValidStream.first, isTrue);
  });
}
