import 'package:dipalza_movil/src/services/diagnostico_gps.dart';
import 'package:flutter_test/flutter_test.dart';

class _Reporte {
  final String motivo;
  final Map<String, Object> claves;
  _Reporte(this.motivo, this.claves);
}

class _ReporteFalso implements ReporteDiagnostico {
  final migas = <String>[];
  final reportes = <_Reporte>[];
  String? usuario;

  @override
  void miga(String mensaje) => migas.add(mensaje);

  @override
  Future<void> identificar(String usuario) async => this.usuario = usuario;

  @override
  Future<void> reportar(String motivo, Map<String, Object> claves) async =>
      reportes.add(_Reporte(motivo, claves));
}

void main() {
  late _ReporteFalso reporte;
  late DateTime ahora;
  late DiagnosticoGps diagnostico;

  setUp(() {
    reporte = _ReporteFalso();
    ahora = DateTime(2026, 11, 18, 10, 12, 28);
    diagnostico = DiagnosticoGps(
      reporte: reporte,
      ahora: () => ahora,
      estadoTelefono: () async => {'gps_encendido': true, 'bateria_sin_restriccion': false},
    );
  });

  group('al iniciar el servicio', () {
    test('reporta el hueco si el último ciclo guardado tiene más de 2 minutos', () async {
      await diagnostico.alIniciarServicio(ahora.subtract(const Duration(minutes: 18)));

      expect(reporte.reportes, hasLength(1));
      expect(reporte.reportes.single.motivo, 'Servicio GPS reiniciado tras 18 min sin ciclos');
      expect(reporte.reportes.single.claves['hueco_minutos'], 18);
      expect(reporte.reportes.single.claves['bateria_sin_restriccion'], false);
    });

    test('no reporta si el último ciclo es reciente', () async {
      await diagnostico.alIniciarServicio(ahora.subtract(const Duration(seconds: 50)));

      expect(reporte.reportes, isEmpty);
    });

    test('no reporta la primera vez (sin ciclo guardado)', () async {
      await diagnostico.alIniciarServicio(null);

      expect(reporte.reportes, isEmpty);
    });
  });

  group('entre ciclos', () {
    test('reporta cuando entre dos ciclos pasan más de 2 minutos', () async {
      await diagnostico.alCiclo();
      ahora = ahora.add(const Duration(minutes: 7));

      await diagnostico.alCiclo();

      expect(reporte.reportes.single.motivo, 'Servicio GPS sin ciclos durante 7 min');
    });

    test('ciclos cada 30 s no reportan nada', () async {
      for (var i = 0; i < 5; i++) {
        await diagnostico.alCiclo();
        ahora = ahora.add(const Duration(seconds: 30));
      }

      expect(reporte.reportes, isEmpty);
    });

    test('cada ciclo deja una miga y devuelve la hora a guardar', () async {
      final guardar = await diagnostico.alCiclo();

      expect(guardar, ahora);
      expect(reporte.migas, isNotEmpty);
    });
  });

  group('fallas del GPS', () {
    test('reporta una sola vez al llegar a 5 fallas seguidas', () async {
      for (var i = 0; i < 7; i++) {
        await diagnostico.alFallarGps('Tiempo agotado');
      }

      expect(reporte.reportes, hasLength(1));
      expect(reporte.reportes.single.motivo, 'GPS sin posición en 5 ciclos seguidos');
      expect(reporte.reportes.single.claves['ultimo_error'], 'Tiempo agotado');
    });

    test('una posición obtenida reinicia la racha', () async {
      for (var i = 0; i < 4; i++) {
        await diagnostico.alFallarGps('Tiempo agotado');
      }
      diagnostico.alObtenerPosicion();
      for (var i = 0; i < 4; i++) {
        await diagnostico.alFallarGps('Tiempo agotado');
      }

      expect(reporte.reportes, isEmpty);
    });

    test('tras recuperarse, una nueva racha de 5 se reporta de nuevo', () async {
      for (var i = 0; i < 5; i++) {
        await diagnostico.alFallarGps('Tiempo agotado');
      }
      diagnostico.alObtenerPosicion();
      for (var i = 0; i < 5; i++) {
        await diagnostico.alFallarGps('GPS desactivado');
      }

      expect(reporte.reportes, hasLength(2));
    });
  });

  test('si falla el reporte o el estado del teléfono, no lanza excepción', () async {
    final conFallas = DiagnosticoGps(
      reporte: reporte,
      ahora: () => ahora,
      estadoTelefono: () async => throw Exception('plugin no disponible'),
    );

    await conFallas.alIniciarServicio(ahora.subtract(const Duration(minutes: 30)));

    expect(reporte.reportes.single.claves['hueco_minutos'], 30);
  });
}
