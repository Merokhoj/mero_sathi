import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_intent_processor.dart';

class AIService {
  static const String _apiKey = "YOUR_GEMINI_API_KEY"; // Placeholder
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  Future<AIIntent> processVoiceCommand(String text) async {
    final prompt = """
Analyze this user voice command: "$text".
Map it to one of these intents: SEND_EMAIL, MAKE_CALL, SEND_SMS, CHECK_CALENDAR, ADD_CALENDAR, CHECK_DRIVE, CHECK_TIME.
Return JSON ONLY: {"action": "INTENT_NAME", "params": {}}
""";
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonResponse = response.text ?? "";
      // Normally we'd parse JSON here, for now using Keyword processor as backup
      return AIIntentProcessor.parse(text); 
    } catch (e) {
      return AIIntentProcessor.parse(text); // Fallback to keyword-based
    }
  }
}
