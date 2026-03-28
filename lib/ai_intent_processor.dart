class AIIntent {
  final String action;
  final Map<String, dynamic> params;
  AIIntent(this.action, this.params);
}
class AIIntentProcessor {
  static AIIntent parse(String text) {
    text = text.toLowerCase();
    if (text.contains('मेल') || text.contains('email')) return AIIntent('SEND_EMAIL', {});
    if (text.contains('कल') || text.contains('phone') || text.contains('call')) return AIIntent('MAKE_CALL', {});
    if (text.contains('सन्देश') || text.contains('message') || text.contains('sms')) return AIIntent('SEND_SMS', {});
    if (text.contains('समय') || text.contains('time')) return AIIntent('CHECK_TIME', {});
    return AIIntent('UNKNOWN', {});
  }
}
