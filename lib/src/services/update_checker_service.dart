import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../share/prefs_usuario.dart';

/// Consulta 'version.json' en el servidor y, si hay una versión más nueva
/// disponible, muestra un diálogo ofreciendo descargarla. Solo aplica en
/// Android: en iOS una app fuera de la App Store no puede autoactualizarse,
/// así que el chequeo ni se ejecuta. Es un aviso de cortesía — cualquier
/// falla de red o de formato se ignora en silencio, nunca interrumpe el
/// arranque de la app.
Future<void> verificarNuevaVersionDisponible(BuildContext context) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  final prefs = PreferenciasUsuario();
  final urlBase = prefs.urlBase;
  if (urlBase.isEmpty) return;

  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final resp = await dio.get('$urlBase/downloads/version.json');

    final data = resp.data is String
        ? jsonDecode(resp.data as String)
        : resp.data;
    final versionRemota = data is Map ? data['version'] as String? : null;
    if (versionRemota == null || versionRemota.isEmpty) return;

    final info = await PackageInfo.fromPlatform();
    if (!esVersionMasNueva(versionRemota, info.version)) return;

    if (!context.mounted) return;
    await _mostrarDialogoNuevaVersion(
        context, versionRemota, '$urlBase/downloads/dipalza-app.apk');
  } catch (_) {
    // Chequeo de cortesía: cualquier error se ignora en silencio.
  }
}

/// Compara versiones semánticas 'X.Y.Z' (ignora sufijos de build tipo
/// '+18'). Cualquier segmento faltante o no numérico se trata como 0.
bool esVersionMasNueva(String remota, String local) {
  final r = _partesVersion(remota);
  final l = _partesVersion(local);
  for (var i = 0; i < 3; i++) {
    if (r[i] != l[i]) return r[i] > l[i];
  }
  return false;
}

List<int> _partesVersion(String version) {
  final partes = version.split('+').first.split('.');
  return List.generate(
      3, (i) => i < partes.length ? (int.tryParse(partes[i]) ?? 0) : 0);
}

Future<void> _mostrarDialogoNuevaVersion(
    BuildContext context, String version, String urlDescarga) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nueva versión disponible'),
      content: Text(
          'Hay una nueva versión de la app (v$version). ¿Deseas descargarla ahora?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Más tarde'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await launchUrl(
              Uri.parse(urlDescarga),
              mode: LaunchMode.externalApplication,
            );
          },
          child: const Text('Descargar'),
        ),
      ],
    ),
  );
}
