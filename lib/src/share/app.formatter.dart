import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._(); // constructor privado

  // --- Formateadores ---
  static final formatoMoneda = NumberFormat(
    // Sin espacio tras el símbolo ("$4.992"), igual que getValorModena en
    // el resto de la app.
    '\$###,##0',
    'es_CL', // <-- El locale para los separadores (punto de mil)
  );

  static final formatoCantidad = NumberFormat(
    '###,##0.00', // <-- El patrón: Símbolo, espacio, y números
    'es_CL', // <-- El locale para los separadores (punto de mil)
  );

  static final DateFormat formatoFecha = DateFormat('dd-MM-yyyy', 'es_CL');
}
