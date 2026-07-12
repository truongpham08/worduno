import 'package:worduno/core/tts/application/services/i_tts_service.dart';
import 'package:worduno/app/di/injection.dart';

/// Bootstraps get_it for widget/integration tests.
///
/// TTS plugin is unavailable in the test environment, so a no-op fake is
/// registered when native init fails.
Future<void> setupWordunoTestDependencies() async {
  if (!getIt.isRegistered<ITtsService>()) {
    try {
      await setupDependencies();
    } catch (_) {
      // setupDependencies registers services before calling TTS init.
    }
  }

  if (getIt.isRegistered<ITtsService>()) {
    await getIt.unregister<ITtsService>();
  }
  getIt.registerLazySingleton<ITtsService>(FakeTtsService.new);
}

class FakeTtsService implements ITtsService {
  bool speakSuccess = true;

  @override
  Future<void> init() async {}

  @override
  Future<bool> speakTerm(String term) async => speakSuccess;

  @override
  Future<void> stop() async {}
}
