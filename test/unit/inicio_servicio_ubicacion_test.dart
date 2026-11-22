import 'package:dipalza_movil/src/services/background_location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('si el servicio ya corre no se vuelve a iniciar', () async {
    var inicios = 0;

    await iniciarServicioUbicacion(
      estaCorriendo: () async => true,
      iniciar: () async {
        inicios++;
        return true;
      },
    );

    expect(inicios, 0);
  });

  test('si el servicio no corre se inicia una vez', () async {
    var inicios = 0;

    await iniciarServicioUbicacion(
      estaCorriendo: () async => false,
      iniciar: () async {
        inicios++;
        return true;
      },
    );

    expect(inicios, 1);
  });
}
