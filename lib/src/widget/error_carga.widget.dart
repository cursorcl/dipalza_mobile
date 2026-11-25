import 'package:dipalza_movil/src/provider/sin_conexion_exception.dart';
import 'package:dipalza_movil/src/utils/mensaje_error.dart';
import 'package:flutter/material.dart';

/// Estado de error de una lista que no se pudo cargar: mensaje para el
/// vendedor (sin detalles técnicos) y botón "Reintentar".
class ErrorCarga extends StatelessWidget {
  final Object error;

  /// Qué se intentaba, en infinitivo: "cargar las ventas".
  final String accion;
  final VoidCallback onReintentar;

  const ErrorCarga({
    super.key,
    required this.error,
    required this.accion,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final sinConexion = error is SinConexionException || SinConexionException.desde(error) != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sinConexion ? Icons.wifi_off : Icons.error_outline,
                color: Colors.red, size: 60),
            const SizedBox(height: 12),
            Text(
              mensajeParaVendedor(error, accion: accion),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
