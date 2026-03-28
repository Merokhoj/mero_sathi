import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
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
Return JSON ONLY: {"action": "INTENT_NAME", "params": {"key": "value"}}
""";
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String jsonResponse = response.text ?? "{}";
      
      // Sanitizing code blocks if Gemini includes them
      jsonResponse = jsonResponse.replaceAll("```json", "").replaceAll("```", "").trim();
      
      final Map<String, dynamic> data = json.decode(jsonResponse);
      return AIIntent(
        data['action'] ?? "UNKNOWN",
        Map<String, dynamic>.from(data['params'] ?? {}),
      );
    } catch (e) {
      // Fallback to keyword-based if Gemini fails or returns invalid JSON
      return AIIntentProcessor.parse(text);
    }
  }
}
