import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistant {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Future<bool> initialize() async {
    final available = await _stt.initialize();
    await _tts.setLanguage('ne-NP'); // Defaulting to Nepali for MeroSathi
    await _tts.setPitch(1.0);
    return available;
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> listen(Function(String) onResult) async {
    await _stt.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: 'ne_NP',
    );
  }

  void stop() => _stt.stop();
}
