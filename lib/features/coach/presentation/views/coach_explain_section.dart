import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../domain/entities/coach_entities.dart';

class CoachExplainSection extends StatelessWidget {
  const CoachExplainSection({super.key, required this.result});

  final CoachExplainResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.greenMid),
              SizedBox(width: 8),
              Text(
                'How to use this word',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.usage,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mid,
              height: 1.5,
            ),
          ),
          if (result.contexts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Contexts',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mid,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.contexts
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusPill),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (result.examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Examples',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mid,
              ),
            ),
            const SizedBox(height: 8),
            for (final example in result.examples)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.beigeLight,
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusSm),
                    border: Border.all(color: AppColors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example.sentence,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      if (example.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          example.note,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mid,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
