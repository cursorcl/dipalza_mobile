import 'package:flutter/material.dart';

/// Fondo común de las pantallas: blanco liso.
///
/// Antes era un degradado amarillo con una forma roja/amarilla encima. Se
/// deja el widget (en vez de quitarlo de cada pantalla) para poder cambiar
/// el fondo de toda la app desde un solo lugar.
class FondoWidget extends StatelessWidget {
  const FondoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: SizedBox.expand(),
    );
  }
}
