import 'package:flutter/material.dart';

const _primaryColor = Color(0xFF336C4C);
const _accentColor = Color(0xFF61B396);
const _headingColor = Color(0xFF307A60);
const _backgroundColor = Color(0xFFF6F6F3);

const _titleStyle = TextStyle(
  color: _headingColor,
  fontSize: 22,
  fontWeight: FontWeight.w600,
);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    // primary : boutons, icônes, filtres. secondary : miniatures, vidéo.
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _accentColor,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: _backgroundColor,
    textTheme: const TextTheme(
      // Texte d'accroche de la home.
      headlineLarge: TextStyle(color: _accentColor, fontSize: 32),
      // Titre d'un cours sur sa page de détail.
      headlineSmall: TextStyle(
        color: _headingColor,
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
      // Titres de section (ex. « Nouveauté pédagogique : »).
      titleLarge: _titleStyle,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _backgroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _titleStyle,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    ),
  );
}
