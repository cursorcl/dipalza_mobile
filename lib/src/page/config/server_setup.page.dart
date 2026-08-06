import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../share/prefs_usuario.dart';
import '../../utils/utils.dart';
import '../login/auth_gate.dart';
import 'widgets/servidor_config_fields.dart';

/// Se muestra solo cuando 'servidorHost' está vacío (primera vez que corre
/// la app en el dispositivo, o después de borrar sus datos). Sin esto, la
/// app caía silenciosamente a un servidor por defecto ('ventas.dynalias.net')
/// sin que el usuario lo supiera.
class ServerSetupPage extends StatefulWidget {
  const ServerSetupPage({super.key});

  @override
  State<ServerSetupPage> createState() => _ServerSetupPageState();
}

class _ServerSetupPageState extends State<ServerSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _puertoController = TextEditingController();
  bool _isHttps = true;

  @override
  void dispose() {
    _hostController.dispose();
    _puertoController.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;

    final prefs = PreferenciasUsuario();
    prefs.servidorHost = _hostController.text.trim();
    prefs.servidorPuerto = _puertoController.text.trim();
    prefs.servidorEsquema = _isHttps ? 'https' : 'http';
    ApiClient().dio.options.baseUrl = prefs.urlBase;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.dns_outlined, size: 64, color: colorRojoBase()),
                  const SizedBox(height: 16),
                  const Text(
                    'Configura el servidor',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa la dirección del servidor antes de continuar '
                    '(por ejemplo: ventas.dynalias.net).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  StatefulBuilder(
                    builder: (context, setLocalState) {
                      return ServidorConfigFields(
                        hostController: _hostController,
                        puertoController: _puertoController,
                        isHttps: _isHttps,
                        onEsquemaChanged: (value) =>
                            setLocalState(() => _isHttps = value),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _continuar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorRojoBase(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
