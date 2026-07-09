import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/di/injection.dart';
import 'package:worduno/core/tts/application/services/i_tts_service.dart';
import 'package:worduno/core/tts/presentation/speak_term.dart';

import '../helpers/test_app_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupWordunoTestDependencies();
  });

  testWidgets('speakTermWithFeedback shows snackbar when TTS fails', (tester) async {
    final tts = FakeTtsService()..speakSuccess = false;

    if (getIt.isRegistered<ITtsService>()) {
      await getIt.unregister<ITtsService>();
    }
    getIt.registerLazySingleton<ITtsService>(() => tts);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => speakTermWithFeedback(context, 'hello'),
              child: const Text('Speak'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Speak'));
    await tester.pump();

    expect(
      find.text('Unable to play audio. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('speakTermWithFeedback stays silent when TTS succeeds', (tester) async {
    final tts = FakeTtsService()..speakSuccess = true;

    if (getIt.isRegistered<ITtsService>()) {
      await getIt.unregister<ITtsService>();
    }
    getIt.registerLazySingleton<ITtsService>(() => tts);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => speakTermWithFeedback(context, 'hello'),
              child: const Text('Speak'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Speak'));
    await tester.pump();

    expect(
      find.text('Unable to play audio. Please try again.'),
      findsNothing,
    );
  });
}
