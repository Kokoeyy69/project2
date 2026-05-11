import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  static VoiceService get instance => _instance;

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('[VoiceService] Error: $error'),
        onStatus: (status) => debugPrint('[VoiceService] Status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('[VoiceService] Init error: $e');
      return false;
    }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isInitialized) {
      final ok = await init();
      if (!ok) return;
    }
    if (_isListening) {
      await stopListening();
    }
    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onResult(result.recognizedWords);
        }
      },
      localeId: 'id_ID',
      listenMode: ListenMode.confirmation,
      partialResults: false,
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speech.stop();
    }
  }

  void cancel() {
    _isListening = false;
    _speech.cancel();
  }

  void dispose() {
    _speech.cancel();
    _isInitialized = false;
  }
}
