import 'package:dipalza_movil/src/share/app.formatter.dart';
import 'package:flutter/material.dart';

import '../../model/venta_detalle_model.dart';
import '../../widget/lista.widgets.dart';

/// Fila de un producto dentro de una venta. Con [onModificar] y
/// [onEliminar] muestra el menú ⋮ (venta en edición).
class VentaDetalleTile extends StatelessWidget {
  final VentaDetalleModel item;
  final VoidCallback? onModificar;
  final VoidCallback? onEliminar;

  const VentaDetalleTile({
    Key? key,
    required this.item,
    this.onModificar,
    this.onEliminar,
  }) : super(key: key);

  static const _cifras = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final estiloSecundario =
        TextStyle(fontSize: 14, color: Colors.grey.shade700);

    String cantidadConPiezas =
        (AppFormatters.formatoCantidad.format(item.cantidad) +
                ' ' +
                item.unidad.toLowerCase())
            .trim();
    if (item.piezas > 0) {
      cantidadConPiezas += ' (${item.piezas} pz)';
    }

    final conMenu = onModificar != null && onEliminar != null;

    return TarjetaLista(
      padding: EdgeInsets.fromLTRB(12, 12, conMenu ? 0 : 12, 12),
      onTap: onModificar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Línea 1: producto
                Text(item.nombreProducto.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Línea 2: cantidad × precio unitario
                Text(
                    '$cantidadConPiezas × '
                    '${AppFormatters.formatoMoneda.format(item.precioUnitario)}',
                    style: estiloSecundario.copyWith(fontFeatures: _cifras)),
                const SizedBox(height: 6),
                // Línea 3: descuento (solo si hay) y total de la línea
                Row(
                  children: [
                    if (item.totalDescuento > 0)
                      Text(
                          'Desc. − ${AppFormatters.formatoMoneda.format(item.totalDescuento)}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade700,
                              fontFeatures: _cifras)),
                    const Spacer(),
                    Text(AppFormatters.formatoMoneda.format(item.totalLinea),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFeatures: _cifras)),
                  ],
                ),
              ],
            ),
          ),
          if (conMenu)
            MenuAccionesLista(
              tooltip: 'Acciones del producto',
              onModificar: onModificar!,
              onEliminar: onEliminar!,
            ),
        ],
      ),
    );
  }
}
