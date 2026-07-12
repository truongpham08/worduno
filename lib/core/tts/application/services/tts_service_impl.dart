import 'package:flutter_tts/flutter_tts.dart';

import 'i_tts_service.dart';

class TtsServiceImpl implements ITtsService {
  TtsServiceImpl() : _tts = FlutterTts();

  final FlutterTts _tts;

  static const _language = 'en-US';
  static const _speechRate = 0.5;
  static const _volume = 1.0;

  bool _initialized = false;
  bool _isSpeaking = false;
  String? _currentTerm;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _currentTerm = null;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      _currentTerm = null;
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      _currentTerm = null;
    });

    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(_volume);
    _initialized = true;
  }

  @override
  Future<bool> speakTerm(String term) async {
    final text = term.trim();
    if (text.isEmpty) {
      return false;
    }

    if (!_initialized) {
      await init();
    }

    if (_isSpeaking && _currentTerm == text) {
      await stop();
      return true;
    }

    try {
      if (_isSpeaking) {
        await stop();
      }

      _currentTerm = text;
      await _tts.speak(text);
      return true;
    } catch (_) {
      _isSpeaking = false;
      _currentTerm = null;
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore stop failures; local state is cleared regardless.
    } finally {
      _isSpeaking = false;
      _currentTerm = null;
    }
  }
}
