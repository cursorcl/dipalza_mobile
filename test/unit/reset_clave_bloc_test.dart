import 'package:dipalza_movil/src/bloc/reset_clave_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ResetClaveBloc bloc;

  setUp(() => bloc = ResetClaveBloc());
  tearDown(() => bloc.dispose());

  // Los campos se fijan antes de suscribirse al stream derivado: al ser
  // BehaviorSubjects, la suscripción repite el último valor ya asignado
  // como primer (y único) evento, evitando depender del valor semilla ''.

  test('codigoStream emite error si no son 6 dígitos', () async {
    bloc.changeCodigo('123');
    await expectLater(bloc.codigoStream.first, throwsA(isA<String>()));
  });

  test('codigoStream emite el valor si son 6 dígitos', () async {
    bloc.changeCodigo('123456');
    expect(await bloc.codigoStream.first, '123456');
  });

  test('formValidStream solo emite cuando los 3 campos son válidos', () async {
    bloc.changeCodigo('123456');
    bloc.changeClaveNueva('claveValida1');
    bloc.changeConfirmarClave('claveValida1');

    expect(await bloc.formValidStream.first, isTrue);
  });
}
