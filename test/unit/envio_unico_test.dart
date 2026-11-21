import 'dart:async';

import 'package:dipalza_movil/src/utils/envio_unico.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un segundo toque mientras el primero sigue en curso se ignora', () async {
    final envio = EnvioUnico();
    final completer = Completer<void>();
    var llamadas = 0;

    final primero = envio.ejecutar(() {
      llamadas++;
      return completer.future;
    });
    expect(envio.enCurso, isTrue);

    await envio.ejecutar(() async => llamadas++);
    expect(llamadas, 1);

    completer.complete();
    await primero;
    expect(envio.enCurso, isFalse);
  });

  test('después de terminar (aunque falle) se puede volver a ejecutar', () async {
    final envio = EnvioUnico();
    var llamadas = 0;

    await expectLater(
        envio.ejecutar(() async => throw Exception('sin conexión')), throwsException);
    expect(envio.enCurso, isFalse);

    await envio.ejecutar(() async => llamadas++);
    expect(llamadas, 1);
  });

  test('avisa cuando cambia el estado para refrescar el botón', () async {
    final estados = <bool>[];
    final envio = EnvioUnico(alCambiar: estados.add);

    await envio.ejecutar(() async {});

    expect(estados, [true, false]);
  });
}
