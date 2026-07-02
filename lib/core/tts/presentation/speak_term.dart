import 'package:flutter/material.dart';

import '../../../app/di/injection.dart';
import '../application/services/i_tts_service.dart';

/// Plays term audio and shows a snackbar when playback fails.
Future<void> speakTermWithFeedback(BuildContext context, String term) async {
  final success = await getIt<ITtsService>().speakTerm(term);
  if (!context.mounted || success) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Unable to play audio. Please try again.'),
    ),
  );
}
