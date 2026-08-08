import 'package:dipalza_movil/src/bloc/reset_clave_bloc.dart';
import 'package:dipalza_movil/src/provider/recuperar_clave_provider.dart';
import 'package:dipalza_movil/src/utils/alert_util.dart' as alertUtil;
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../share/app.navigator.dart';

class OlvideClavePage extends StatefulWidget {
  const OlvideClavePage({super.key});

  @override
  State<OlvideClavePage> createState() => _OlvideClavePageState();
}

class _OlvideClavePageState extends State<OlvideClavePage> {
  final _recuperarClaveProvider = RecuperarClaveProvider();
  final _usuarioOEmailController = TextEditingController();
  final _usuarioParaResetController = TextEditingController();

  int _paso = 0; // 0: solicitar código, 1: ingresar código + clave nueva
  bool _isLoading = false;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<ResetClaveBloc>();
        bloc.changeCodigo('');
        bloc.changeClaveNueva('');
        bloc.changeConfirmarClave('');
      }
    });
  }

  @override
  void dispose() {
    _usuarioOEmailController.dispose();
    _usuarioParaResetController.dispose();
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
        child: _paso == 0 ? _pasoSolicitarCodigo() : _pasoRestablecerClave(),
      ),
    );
  }

  Widget _pasoSolicitarCodigo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ingrese su usuario o correo registrado. Si existe una cuenta '
          'asociada, le enviaremos un código de recuperación por correo.',
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
              : _solicitarCodigo,
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text('Enviar código'),
        ),
      ],
    );
  }

  Widget _pasoRestablecerClave() {
    final bloc = context.read<ResetClaveBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Ingrese su usuario, el código recibido por correo y la clave nueva.'),
        const SizedBox(height: 20.0),
        TextField(
          controller: _usuarioParaResetController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person_outline, color: colorRojoBase()),
            labelText: 'Usuario',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16.0),
        StreamBuilder<String>(
          stream: bloc.codigoStream,
          builder: (context, snapshot) {
            return TextField(
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.pin_outlined, color: colorRojoBase()),
                labelText: 'Código de 6 dígitos',
                errorText: snapshot.hasError ? snapshot.error.toString() : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: bloc.changeCodigo,
            );
          },
        ),
        StreamBuilder<String>(
          stream: bloc.claveNuevaStream,
          builder: (context, snapshot) {
            return TextField(
              obscureText: _obscureNueva,
              enabled: !_isLoading,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_reset, color: colorRojoBase()),
                labelText: 'Clave nueva',
                errorText: snapshot.hasError ? snapshot.error.toString() : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNueva ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
                ),
              ),
              onChanged: bloc.changeClaveNueva,
            );
          },
        ),
        const SizedBox(height: 16.0),
        StreamBuilder<String>(
          stream: bloc.confirmarClaveStream,
          builder: (context, snapshot) {
            return TextField(
              obscureText: _obscureConfirmar,
              enabled: !_isLoading,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_reset, color: colorRojoBase()),
                labelText: 'Confirmar clave nueva',
                errorText: snapshot.hasError ? snapshot.error.toString() : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmar ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                ),
              ),
              onChanged: bloc.changeConfirmarClave,
            );
          },
        ),
        const SizedBox(height: 30.0),
        StreamBuilder<bool>(
          stream: bloc.formValidStream,
          builder: (context, snapshot) {
            final habilitado = snapshot.hasData &&
                _usuarioParaResetController.text.trim().isNotEmpty &&
                !_isLoading;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                backgroundColor: colorRojoBase(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: habilitado ? () => _restablecerClave(bloc) : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Text('Restablecer clave'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _solicitarCodigo() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final usuarioOEmail = _usuarioOEmailController.text.trim();
    final resp = await _recuperarClaveProvider.solicitarCodigo(usuarioOEmail);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resp.status == 200) {
      if (!usuarioOEmail.contains('@')) {
        _usuarioParaResetController.text = usuarioOEmail;
      }
      setState(() => _paso = 1);
    } else {
      final mensaje = resp.detalle['error']?.toString() ??
          'No se pudo enviar el código. Intente nuevamente.';
      alertUtil.showAlertDialog(context, mensaje, Icons.error_outline);
    }
  }

  Future<void> _restablecerClave(ResetClaveBloc bloc) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final resp = await _recuperarClaveProvider.restablecerClave(
        _usuarioParaResetController.text.trim(), bloc.codigo, bloc.claveNueva);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resp.status == 200) {
      await alertUtil.showAlertDialog(
          context, 'Clave restablecida correctamente. Ya puede iniciar sesión.', Icons.check_circle_outline);
      if (mounted) AppNavigator.pop();
    } else {
      final mensaje = resp.detalle['error']?.toString() ??
          'No se pudo restablecer la clave. Intente nuevamente.';
      alertUtil.showAlertDialog(context, mensaje, Icons.error_outline);
    }
  }
}
