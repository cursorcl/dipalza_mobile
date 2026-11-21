import 'package:dipalza_movil/src/utils/utils.dart';
import 'package:flutter/material.dart';

/// Piezas visuales comunes de las listas (Ventas, Clientes, Productos y
/// Detalle de venta), para que todas se vean igual y se cambien en un solo
/// lugar.

/// Tarjeta plana con borde gris suave y esquinas redondeadas. Si recibe
/// [onTap], toda la tarjeta responde al toque.
class TarjetaLista extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const TarjetaLista({
    Key? key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 0, 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: color ?? Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Cápsula pequeña con ícono opcional y texto, en tonos de [color].
/// [semantica] reemplaza lo que lee el lector de pantalla, cuando el texto
/// visible solo no basta (p. ej. una hora).
class Capsula extends StatelessWidget {
  final String texto;
  final MaterialColor color;
  final IconData? icono;
  final String? semantica;

  const Capsula({
    Key? key,
    required this.texto,
    required this.color,
    this.icono,
    this.semantica,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final capsula = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 12, color: color.shade900),
            const SizedBox(width: 4),
          ],
          Text(texto,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.shade900,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
    if (semantica == null) return capsula;
    return Semantics(label: semantica, excludeSemantics: true, child: capsula);
  }
}

/// Mensaje centrado para una lista vacía o una búsqueda sin resultados, con
/// una acción opcional (botón relleno si [accionPrincipal], si no de texto).
class EstadoVacioLista extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? textoAccion;
  final IconData? iconoAccion;
  final VoidCallback? onAccion;
  final bool accionPrincipal;

  const EstadoVacioLista({
    Key? key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.textoAccion,
    this.iconoAccion,
    this.onAccion,
    this.accionPrincipal = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      child: Column(
        children: [
          Icon(icono, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(titulo,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (mensaje != null) ...[
            const SizedBox(height: 8),
            Text(mensaje!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
          if (textoAccion != null && onAccion != null) ...[
            const SizedBox(height: 24),
            accionPrincipal
                ? FilledButton.icon(
                    onPressed: onAccion,
                    icon: Icon(iconoAccion ?? Icons.add),
                    label: Text(textoAccion!),
                    style: FilledButton.styleFrom(
                        backgroundColor: colorRojoBase()),
                  )
                : TextButton(onPressed: onAccion, child: Text(textoAccion!)),
          ],
        ],
      ),
    );
  }
}

/// Botón de texto para la barra roja superior ("Nueva Venta", "Agregar",
/// "Finalizar"). Texto blanco sobre el rojo, con borde blanco: el fondo
/// blanco semitransparente de antes dejaba el texto con contraste 2,9:1.
class BotonBarra extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback? onPressed;
  final Widget? iconoPersonalizado;

  const BotonBarra({
    Key? key,
    required this.icono,
    required this.texto,
    required this.onPressed,
    this.iconoPersonalizado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: iconoPersonalizado ?? Icon(icono, size: 20),
        label: Text(texto),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

/// Círculo con las iniciales de un nombre, en tonos de [color]. El nombre
/// ya se lee en la fila, así que se oculta al lector de pantalla.
class AvatarIniciales extends StatelessWidget {
  final String iniciales;
  final MaterialColor color;

  const AvatarIniciales(
      {Key? key, required this.iniciales, this.color = Colors.red})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 20,
        backgroundColor: color == Colors.red ? color.shade50 : color.shade100,
        child: Text(iniciales,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color.shade800)),
      ),
    );
  }
}

/// Menú ⋮ con Modificar y Eliminar: las mismas acciones del deslizar, para
/// que no dependan de un gesto que no se ve.
class MenuAccionesLista extends StatelessWidget {
  final String tooltip;
  final VoidCallback onModificar;
  final VoidCallback onEliminar;

  const MenuAccionesLista({
    Key? key,
    required this.tooltip,
    required this.onModificar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
      onSelected: (accion) =>
          accion == 'modificar' ? onModificar() : onEliminar(),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'modificar',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Modificar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red.shade700),
            title:
                Text('Eliminar', style: TextStyle(color: Colors.red.shade700)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Ancho que ocupa el botón ⋮; se reserva en filas sin menú para que los
/// montos queden alineados.
const double anchoMenuAcciones = 48;
