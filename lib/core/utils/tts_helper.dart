import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  TtsHelper._();

  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.speak(text);
    } catch (e) {
      // Silently catch TTS issues
    }
  }
}
