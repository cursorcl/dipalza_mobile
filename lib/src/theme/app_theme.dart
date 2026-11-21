// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color_scheme.dart';

class AppTheme {
  // TEMA CLARO
  static ThemeData get lightTheme {
    // El esquema nace del rojo corporativo: desde el naranja, Material 3
    // derivaba tonos café/beige que pintaban diálogos y botones sin color
    // propio (p. ej. "Cerrar sesión" en Configuración).
    final appColors = AppColorScheme.fromSeed(
      seedColor: AppColorScheme.rojoCorporativo,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: appColors.toColorScheme(),

      // APPBAR
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),

      // CARDS
      cardTheme: const CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // FLOATING ACTION BUTTON
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        elevation: 6,
      ),

      // INPUT DECORATION
      inputDecorationTheme: InputDecorationTheme(
        border: const UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: appColors.primary,
            width: 2,
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: appColors.rojoBase,
            width: 2,
          ),
        ),
        errorMaxLines: 2,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),

      // ELEVATED BUTTONS
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // OUTLINED BUTTONS
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(
            color: appColors.primary,
            width: 1,
          ),
        ),
      ),

      // LIST TILES
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),

      // DIVIDERS
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
        space: 1,
      ),

      // SCAFFOLD
      scaffoldBackgroundColor: AppColorScheme.grisClaro,

      // EFECTOS
      splashColor: appColors.primary.withOpacity(0.1),
      highlightColor: appColors.primary.withOpacity(0.05),

      // ICONOS
      iconTheme: const IconThemeData(
        color: Colors.grey,
        size: 24,
      ),
    );
  }

  // TEMA OSCURO (opcional)
  static ThemeData get darkTheme {
    final appColors = AppColorScheme.fromSeedDark(
      seedColor: AppColorScheme.naranjaCorporativo,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: appColors.toColorScheme().copyWith(
            brightness: Brightness.dark,
          ),

      // ... configuración similar pero para tema oscuro
      scaffoldBackgroundColor: AppColorScheme.grisOscuro,
    );
  }

  // MÉTODO PARA CREAR APPCOLORS CON EL TEMA
  static AppColorScheme createAppColors(
      {Brightness brightness = Brightness.light}) {
    return brightness == Brightness.light
        ? AppColorScheme.fromSeed(
            seedColor: AppColorScheme.naranjaCorporativo,
            brightness: brightness,
          )
        : AppColorScheme.fromSeedDark(
            seedColor: AppColorScheme.naranjaCorporativo,
          );
  }
}
