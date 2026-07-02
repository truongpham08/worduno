import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared star toggle used across Home, Learning, and Exam filters.
class StarToggleButton extends StatelessWidget {
  const StarToggleButton({
    super.key,
    required this.isStarred,
    required this.onToggle,
    this.size = 32,
  });

  final bool isStarred;
  final VoidCallback onToggle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isStarred ? AppColors.beigeLight : AppColors.bg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onToggle,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            isStarred ? Icons.star_rounded : Icons.star_border_rounded,
            color: isStarred ? AppColors.coralMid : AppColors.light,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
