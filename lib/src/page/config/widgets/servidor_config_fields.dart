import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campos reutilizables para capturar host, puerto (opcional) y esquema
/// (http/https) del servidor. El caller es dueño de los controllers y del
/// estado del esquema seleccionado (SegmentedButton no mantiene estado
/// propio, así que un cambio de esquema debe reflejarse reconstruyendo este
/// widget con [isHttps] actualizado).
class ServidorConfigFields extends StatelessWidget {
  final TextEditingController hostController;
  final TextEditingController puertoController;
  final bool isHttps;
  final ValueChanged<bool> onEsquemaChanged;

  const ServidorConfigFields({
    super.key,
    required this.hostController,
    required this.puertoController,
    required this.isHttps,
    required this.onEsquemaChanged,
  });

  static String? validarHost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el servidor';
    }
    return null;
  }

  static String? validarPuerto(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    final puerto = int.tryParse(value.trim());
    if (puerto == null || puerto <= 0 || puerto > 65535) {
      return 'Puerto inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: hostController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Servidor',
            hintText: 'ventas.dynalias.net',
            prefixIcon: Icon(Icons.dns),
          ),
          validator: validarHost,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: puertoController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Puerto (opcional)',
            hintText: 'Por defecto según el esquema',
            prefixIcon: Icon(Icons.numbers),
          ),
          validator: validarPuerto,
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('HTTP')),
            ButtonSegment(value: true, label: Text('HTTPS')),
          ],
          selected: {isHttps},
          onSelectionChanged: (seleccion) => onEsquemaChanged(seleccion.first),
        ),
      ],
    );
  }
}
