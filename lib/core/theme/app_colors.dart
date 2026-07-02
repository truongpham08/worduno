import 'package:flutter/material.dart';

/// Lexia design palette — flat colors from lexia-preview.
abstract final class AppColors {
  static const bg = Color(0xFFEAEAEA);
  static const white = Color(0xFFFFFFFF);
  static const greenDark = Color(0xFF1A433D);
  static const greenMid = Color(0xFF557E7A);
  static const green = Color(0xFFB8D4CF);
  static const coralDark = Color(0xFFE06B45);
  static const coralMid = Color(0xFFF48C62);
  static const coral = Color(0xFFFFBF9A);
  static const beige = Color(0xFFFFD9C2);
  static const beigeLight = Color(0xFFFFF2EA);
  static const blue = Color(0xFFC5DDD9);
  static const purple = Color(0xFFD4E4E1);
  static const ink = Color(0xFF1A433D);
  static const mid = Color(0xFF557E7A);
  static const light = Color(0xFF9AB2AE);
  static const border = Color(0xFFD4D4D4);
  static const surface = Color(0xFFF4F4F4);

  // Semantic aliases
  static const primary = greenDark;
  static const onPrimary = white;
  static const secondary = coralDark;
  static const error = coralDark;
  static const errorBg = beigeLight;
  static const errorBorder = coral;
  static const success = greenDark;
  static const successBg = green;
  static const warning = coralMid;
  static const warningBg = beigeLight;

  static Color withAlpha27(Color color) => color.withValues(alpha: 0.27);
  static Color withAlpha33(Color color) => color.withValues(alpha: 0.2);
  static Color withAlpha55(Color color) => color.withValues(alpha: 0.33);

  static const levelPalettes = <LevelPalette>[
    LevelPalette(bg: green, accent: greenDark),
    LevelPalette(bg: beigeLight, accent: coralDark),
    LevelPalette(bg: blue, accent: greenMid),
    LevelPalette(bg: green, accent: greenMid),
  ];

  static const unitPalettes = <UnitPalette>[
    UnitPalette(bg: green, accent: greenDark),
    UnitPalette(bg: beigeLight, accent: coralDark),
    UnitPalette(bg: coral, accent: coralMid),
    UnitPalette(bg: blue, accent: greenMid),
    UnitPalette(bg: green, accent: greenMid),
    UnitPalette(bg: beigeLight, accent: coralMid),
  ];

  static LevelPalette levelPalette(int index) =>
      levelPalettes[index % levelPalettes.length];

  static UnitPalette unitPalette(int index) =>
      unitPalettes[index % unitPalettes.length];

  static LevelPalette levelPaletteForCode(String code) {
    final c = code.toLowerCase();
    if (c.contains('b1')) return levelPalettes[0];
    if (c.contains('b2')) return levelPalettes[1];
    if (c.contains('c')) return levelPalettes[2];
    return levelPalettes[indexFromCode(code)];
  }

  static int indexFromCode(String code) =>
      code.toLowerCase().hashCode.abs();

  static WordStatusPalette wordStatus(String status) {
    switch (status.toLowerCase()) {
      case 'learned':
        return const WordStatusPalette(bg: green, fg: greenDark);
      case 'learning':
        return const WordStatusPalette(bg: beigeLight, fg: coralMid);
      default:
        return const WordStatusPalette(bg: blue, fg: greenMid);
    }
  }

  static ScorePalette examScore(double score) {
    if (score >= 0.8) {
      return const ScorePalette(bg: green, fg: greenDark);
    }
    if (score >= 0.6) {
      return const ScorePalette(bg: beigeLight, fg: coralMid);
    }
    return const ScorePalette(bg: coral, fg: coralDark);
  }
}

class LevelPalette {
  const LevelPalette({required this.bg, required this.accent});

  final Color bg;
  final Color accent;
}

class UnitPalette {
  const UnitPalette({required this.bg, required this.accent});

  final Color bg;
  final Color accent;
}

class WordStatusPalette {
  const WordStatusPalette({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}

class ScorePalette {
  const ScorePalette({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}
