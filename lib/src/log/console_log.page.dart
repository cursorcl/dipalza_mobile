import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../share/prefs_usuario.dart';
import '../utils/utils.dart';
import 'db_log_provider.dart';
import 'log_model.dart';

class ConsoleLogPage extends StatefulWidget {
  @override
  _ConsoleLogPageState createState() => _ConsoleLogPageState();
}

class _ConsoleLogPageState extends State<ConsoleLogPage> {
  late LogModel ultimoLog;
  final List<Container> _logs = <Container>[];
  final ScrollController _scrollController = new ScrollController();
  bool _enviandoLogs = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadLogsHistorico();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: colorRojoBase(),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Console LOG'),
          actions: <Widget>[
            if (kDebugMode)
              IconButton(
                icon: const Icon(Icons.bug_report),
                tooltip: 'Forzar crash de prueba',
                onPressed: _forzarCrashDePrueba,
              ),
            IconButton(
              icon: _enviandoLogs
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share),
              tooltip: 'Enviar logs',
              onPressed: _enviandoLogs ? null : _enviarLogs,
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          child: ListView.builder(
            controller: _scrollController,
            itemBuilder: (context, int index) => _logs[index],
            itemCount: _logs.length,
            reverse: true,
            padding: const EdgeInsets.all(.0),
          ),
        ),
    );
  }

  /// Solo visible en debug: fuerza un crash real (a través de Crashlytics)
  /// para verificar que la captura de errores y la subida a Firebase
  /// funcionan de punta a punta, sin depender de un crash real en terreno.
  void _forzarCrashDePrueba() {
    FirebaseCrashlytics.instance.crash();
  }

  /// Exporta todos los logs guardados localmente a un archivo de texto y
  /// abre el selector nativo para compartirlo (WhatsApp, correo, etc.) --
  /// pensado para que un vendedor en terreno pueda mandar sus logs cuando
  /// la app se cayó o se comportó de forma extraña.
  Future<void> _enviarLogs() async {
    setState(() => _enviandoLogs = true);
    try {
      final logs = await DBLogProvider.db.getTodos();
      final paqueteInfo = await PackageInfo.fromPlatform();
      final vendedor = PreferenciasUsuario().vendedor;

      final buffer = StringBuffer()
        ..writeln('Logs Dipalza Móvil')
        ..writeln('Versión: ${paqueteInfo.version}+${paqueteInfo.buildNumber}')
        ..writeln('Vendedor: ${vendedor.isEmpty ? '(sin sesión)' : vendedor}')
        ..writeln('Generado: ${DateTime.now()}')
        ..writeln('Cantidad de registros: ${logs.length}')
        ..writeln('---');
      for (final item in logs) {
        buffer.writeln(item.log);
      }

      final directorioTemporal = await getTemporaryDirectory();
      final marcaTiempo = DateTime.now().millisecondsSinceEpoch;
      final archivo = File('${directorioTemporal.path}/dipalza_logs_$marcaTiempo.txt');
      await archivo.writeAsString(buffer.toString());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(archivo.path)],
          subject: 'Logs Dipalza Móvil - $vendedor',
        ),
      );
    } finally {
      if (mounted) setState(() => _enviandoLogs = false);
    }
  }

  void _loadLogs() async {
    final List<LogModel> listaLogs = await DBLogProvider.db.getLogs(20);

    if (listaLogs.isNotEmpty) {
      ultimoLog = listaLogs[listaLogs.length - 1];
    }

    for (var item in listaLogs.reversed) {
      _creaTextoLog(item);
    }
  }

  Future<Null> _loadLogsHistorico() async {
    final List<LogModel> listaLogs =
        await DBLogProvider.db.getLogPaginados(ultimoLog, 10);

    if (listaLogs.isNotEmpty) {
      ultimoLog = listaLogs[listaLogs.length - 1];
    }

    for (var item in listaLogs) {
      _creaTextoLogHistorico(item);
    }
  }

  void _creaTextoLog(LogModel item) {
    setState(() {
      var texto = Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          item.log,
          maxLines: 1000,
          style: const TextStyle(color: Colors.black87, fontSize: 11.0),
        ),
      );
      _logs.insert(0, texto);
    });
  }

  void _creaTextoLogHistorico(LogModel item) {
    setState(() {
      var texto = Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          item.log,
          maxLines: 1000,
          style: const TextStyle(color: Colors.black87, fontSize: 11.0),
        ),
      );
      _logs.insert(_logs.length, texto);
    });
  }
}
