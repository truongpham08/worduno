import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared radii and shadows from lexia-preview.
abstract final class AppDecorations {
  static const radiusSm = 12.0;
  static const radiusMd = 18.0;
  static const radiusLg = 24.0;
  static const radiusXl = 32.0;
  static const radiusPill = 999.0;

  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: AppColors.greenDark.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: AppColors.greenDark.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: AppColors.greenDark.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: shadowMd,
      );

  static BoxDecoration pillButton(Color color) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radiusPill),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
