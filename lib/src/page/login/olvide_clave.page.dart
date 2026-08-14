import 'package:dipalza_movil/src/provider/recuperar_clave_provider.dart';
import 'package:dipalza_movil/src/utils/alert_util.dart' as alertUtil;
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:flutter/material.dart';

import '../../share/app.navigator.dart';

class OlvideClavePage extends StatefulWidget {
  const OlvideClavePage({super.key});

  @override
  State<OlvideClavePage> createState() => _OlvideClavePageState();
}

class _OlvideClavePageState extends State<OlvideClavePage> {
  final _recuperarClaveProvider = RecuperarClaveProvider();
  final _usuarioOEmailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usuarioOEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorRojoBase(),
        title: const Text('Recuperar contraseña'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingrese su usuario o correo registrado. Si existe una cuenta '
              'asociada, le enviaremos una clave temporal por correo — '
              'deberá cambiarla al iniciar sesión con ella.',
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _usuarioOEmailController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_outline, color: colorRojoBase()),
                labelText: 'Usuario o correo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                backgroundColor: colorRojoBase(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (_usuarioOEmailController.text.trim().isEmpty || _isLoading)
                  ? null
                  : _solicitarRecuperacion,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _solicitarRecuperacion() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final resp = await _recuperarClaveProvider
        .solicitarRecuperacion(_usuarioOEmailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resp.status == 200) {
      await alertUtil.showAlertDialog(
          context,
          'Si la cuenta existe, revisa tu correo: te enviamos una clave temporal.',
          Icons.check_circle_outline);
      if (mounted) AppNavigator.pop();
    } else {
      final mensaje = resp.detalle['error']?.toString() ??
          'No se pudo enviar la solicitud. Intente nuevamente.';
      alertUtil.showAlertDialog(context, mensaje, Icons.error_outline);
    }
  }
}
