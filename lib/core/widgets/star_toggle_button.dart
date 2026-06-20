import 'package:flutter/material.dart';

/// Shared star toggle used across Home, Learning, and Exam filters.
/// Calls [onToggle] supplied by the hosting ViewModel via service layer.
class StarToggleButton extends StatelessWidget {
  const StarToggleButton({
    super.key,
    required this.isStarred,
    required this.onToggle,
  });

  final bool isStarred;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(isStarred ? Icons.star : Icons.star_border),
      color: isStarred ? Colors.amber : null,
    );
  }
}
