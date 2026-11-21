import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Asegúrate de tener esta dependencia

import '../../provider/vendedor_ruta_provider.dart';
import '../../services/api_client.dart';
import '../../share/app.navigator.dart';
import '../../share/app_routes.dart';
import '../../share/prefs_usuario.dart';
import '../../utils/utils.dart';

class AuthGate extends StatefulWidget {
  /// Permite inyectar un [ApiClient] durante los tests. En la app real se
  /// usa el singleton por defecto.
  final ApiClient? apiClient;

  const AuthGate({super.key, this.apiClient});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  @override
  void initState() {
    super.initState();
    // Ejecutamos la validación apenas arranca el widget
    // Usamos addPostFrameCallback para asegurar que el contexto esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    // 1. (Opcional) Pequeña pausa para que se vea tu logo y no sea un parpadeo
    await Future.delayed(const Duration(seconds: 2));

    // 2. Verificar Sesión
    final prefs = PreferenciasUsuario();
    final refreshToken = prefs.refreshToken;

    // Asumimos inválido por defecto
    bool isSessionValid = false;

    if (refreshToken.isNotEmpty) {
      try {
        // Si el token es basura, JwtDecoder lanzará excepción y caeremos al catch.
        bool isExpired = JwtDecoder.isExpired(refreshToken);

        if (!isExpired) {
          final resultado = await _apiClient.renovarToken();
          if (resultado.exitoso && !resultado.mustChangePassword) {
            isSessionValid = true;
          } else {
            // La renovación falló, o tuvo éxito pero el usuario todavía
            // tiene pendiente el cambio de clave obligatorio: no debe
            // llegar a Home saltándose esa pantalla. Se trata igual que una
            // sesión inválida (cae al 'else' de más abajo, que borra
            // credenciales y manda a login; ahí login.page.dart detecta
            // mustChangePassword y lo lleva a CambiarClaveObligatorioPage).
            isSessionValid = false;
          }
        } else {
          developer.log('El token tiene formato válido pero ha expirado.', name: 'AuthGate');
        }
      } catch (e) {
        // AQUÍ CAPTURAMOS TU ERROR
        developer.log('Error al decodificar token (formato inválido)', name: 'AuthGate', error: e);
        isSessionValid = false;
      }
    }

    // 4. Verificar rutas asignadas (solo si la sesión sigue siendo válida)
    bool tieneRutasAsignadas = true;
    if (isSessionValid && prefs.tipo.isEmpty) {
      // Sesión restaurada por refresh token sin 'tipo' guardado localmente
      // (ocurre con sesiones antiguas, de antes de que el login empezara a
      // persistirlo). Sin 'tipo' la consulta de rutas arma una URL inválida
      // (.../vendedores/{codigo}//rutas) y el backend responde 400. Forzamos
      // un login explícito para que 'tipo' quede guardado correctamente.
      isSessionValid = false;
    } else if (isSessionValid) {
      try {
        final rutas = await VendedorRutaProvider()
            .obtenerRutasAsignadas(prefs.vendedor, prefs.tipo);
        tieneRutasAsignadas = rutas.isNotEmpty;
      } catch (e) {
        // Fallo de red/servidor al consultar: no bloqueamos una sesión
        // válida por un error transitorio ajeno a la asignación de rutas.
        developer.log('Error al verificar rutas asignadas', name: 'AuthGate', error: e);
        tieneRutasAsignadas = true;
      }
    }

    // 5. Navegación
    if (!mounted) return; // Seguridad por si el usuario cerró la app

    if (isSessionValid && tieneRutasAsignadas) {
      // Usamos pushReplacementNamed para que no pueda volver atrás al Splash
      AppNavigator.pushReplacementNamed(AppRoutes.home);
    } else if (isSessionValid && !tieneRutasAsignadas) {
      // Sesión válida pero sin rutas: anulamos el refresh token recuperado
      // y obligamos a reconectar para pasar por la selección de rutas.
      await prefs.borrarCredenciales();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.login,
        arguments: {'sinRutasAsignadas': true},
      );
    } else {
      await prefs.borrarCredenciales();
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mismo fondo blanco y mismo logo que la pantalla de arranque nativa, así
    // el paso de una a otra no se nota (antes: un ícono de escudo azul).
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image/logo_dipalza_transparente.png',
              width: 160,
              semanticLabel: 'Dipalza',
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: colorRojoBase()),
            const SizedBox(height: 16),
            Text(
              "Iniciando sistema...",
              style: TextStyle(color: Colors.grey.shade700),
            )
          ],
        ),
      ),
    );
  }
}