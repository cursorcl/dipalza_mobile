import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_color_scheme.dart';
import '../validacion/rut_validator.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

HexColor colorIconHome() {
  return HexColor('#1464f6');
}

/// Rojo de las barras y botones principales. Se define una sola vez, en
/// AppColorScheme.rojoCorporativo.
Color colorRojoBase() => AppColorScheme.rojoCorporativo;

HexColor colorVerdeBase() {
  return HexColor('#004300');
}

/// Formatea un valor como CLP con separador y sin decimales
String getValorModena(double valor, int decimal) {
  final format = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '',
    decimalDigits: decimal,
  );
  return '\$${format.format(valor)}';
}

/// Formatea un número sin decimales
String getValorNumero(double valor) {
  final format = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '',
    decimalDigits: 0,
  );
  return format.format(valor).trim();
}

/// Formatea un número con N decimales
String getValorNumeroDecimal(double valor, int decimal) {
  final format = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '',
    decimalDigits: decimal,
  );
  return format.format(valor).trim();
}

String getFormatRut(String rut) {
  while (rut.startsWith('0')) {
    rut = rut.substring(1, rut.length);
  }
  rut = RUTValidator.formatear(rut);
  return rut;
}

String getFormatRutToService(String usuario) {
  String rut = usuario.replaceAll(".", "").replaceAll("-", "");
  while (rut.length < 10) {
    rut = '0' + rut;
  }
  return rut;
}

/// Formatos de fechas y horas
DateFormat formatoFecha() => DateFormat("dd MMM yyyy", 'es_CL');
DateFormat formatoFechaCorta() => DateFormat("dd/MM/yyyy", 'es_CL');
DateFormat formatoFechaCortaHora() => DateFormat("dd/MM/yyyy HH:mm", 'es_CL');
DateFormat formatoHora() => DateFormat("HH:mm", 'es_CL');
