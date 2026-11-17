import 'package:flutter/services.dart';

/// Teclado de los campos donde se busca un producto por código o nombre
/// (ítem de venta y lista de productos).
///
/// `visiblePassword` es la forma de que Android muestre letras y la fila de
/// números a la vez (Gboard y el teclado de Samsung la muestran siempre en
/// este tipo): `number` solo deja escribir números y `text` esconde los números
/// detrás de la tecla "?123". En iOS se ve como un teclado de letras normal.
const TextInputType tecladoBusquedaProducto = TextInputType.visiblePassword;
