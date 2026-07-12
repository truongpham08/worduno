/// Text-to-speech for vocabulary terms (spec §12: term only, via flutter_tts).
abstract class ITtsService {
  Future<void> init();

  /// Speaks [term]. Returns `false` when playback fails (show UI feedback).
  ///
  /// If the same term is already playing, stops playback and returns `true`.
  Future<bool> speakTerm(String term);

  Future<void> stop();
}
