class AIIntent {
  final String action;
  final Map<String, dynamic> params;
  AIIntent(this.action, this.params);
}

class AIIntentProcessor {
  static AIIntent parse(String text) {
    text = text.toLowerCase();
    
    if (text.contains("मेल") || text.contains("email")) return AIIntent("SEND_EMAIL", {});
    if (text.contains("कल") || text.contains("phone") || text.contains("call")) return AIIntent("MAKE_CALL", {});
    if (text.contains("सन्देश") || text.contains("message") || text.contains("sms")) return AIIntent("SEND_SMS", {});
    if (text.contains("समय") || text.contains("time")) return AIIntent("CHECK_TIME", {});
    
    // New Intents
    if (text.contains("क्यालेन्डर") || text.contains("calendar") || text.contains("schedule") || text.contains("मीटिंग")) return AIIntent("CHECK_CALENDAR", {});
    if (text.contains("ड्राइभ") || text.contains("drive") || text.contains("फाइल")) return AIIntent("CHECK_DRIVE", {});
    if (text.contains("थप") || text.contains("add") || text.contains("मिनेट")) return AIIntent("ADD_CALENDAR", {"title": "New Meeting"});

    return AIIntent("UNKNOWN", {});
  }
}
