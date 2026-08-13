import 'package:dipalza_movil/src/bloc/cambiar_clave_bloc.dart';
import 'package:dipalza_movil/src/provider/usuario_provider.dart';
import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:dipalza_movil/src/share/prefs_usuario.dart';
import 'package:dipalza_movil/src/utils/alert_util.dart' as alertUtil;
import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CambiarClaveObligatorioPage extends StatefulWidget {
  final String claveActual;
  const CambiarClaveObligatorioPage({super.key, required this.claveActual});

  @override
  State<CambiarClaveObligatorioPage> createState() =>
      _CambiarClaveObligatorioPageState();
}

class _CambiarClaveObligatorioPageState
    extends State<CambiarClaveObligatorioPage> {
  bool _isLoading = false;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<CambiarClaveBloc>();
        bloc.changeClaveActual(widget.claveActual);
        bloc.changeClaveNueva('');
        bloc.changeConfirmarClave('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CambiarClaveBloc>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorRojoBase(),
          title: const Text('Debes cambiar tu clave'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Por seguridad, debes elegir una clave nueva antes de continuar.',
              ),
              const SizedBox(height: 20.0),
              _campoClaveNueva(bloc),
              const SizedBox(height: 16.0),
              _campoConfirmarClave(bloc),
              const SizedBox(height: 30.0),
              _botonGuardar(bloc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoClaveNueva(CambiarClaveBloc bloc) {
    return StreamBuilder<String>(
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
    );
  }

  Widget _campoConfirmarClave(CambiarClaveBloc bloc) {
    return StreamBuilder<String>(
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
    );
  }

  Widget _botonGuardar(CambiarClaveBloc bloc) {
    return StreamBuilder<bool>(
      stream: bloc.formValidStream,
      builder: (context, snapshot) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            backgroundColor: colorRojoBase(),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: (snapshot.hasData && !_isLoading) ? () => _guardar(bloc) : null,
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text('Guardar'),
        );
      },
    );
  }

  Future<void> _guardar(CambiarClaveBloc bloc) async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final usuarioProvider = UsuarioProvider();
    final prefs = PreferenciasUsuario();
    final resp = await usuarioProvider.cambiarClave(widget.claveActual, bloc.claveNueva);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resp.status == 200) {
      await prefs.borrarCredenciales();
      if (mounted) AppNavigator.goToLogin();
    } else {
      final mensaje =
          resp.detalle['error']?.toString() ?? 'No se pudo cambiar la clave. Intente nuevamente.';
      alertUtil.showAlertDialog(context, mensaje, Icons.error_outline);
    }
  }
}
