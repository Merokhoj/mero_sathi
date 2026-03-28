import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'voice_assistant.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static final VoiceAssistant _voice = VoiceAssistant();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Initialize notification listener
    await NotificationsListener.initialize(
      callbackHandle: _onNotification,
    );
  }

  static void _onNotification(NotificationEvent event) {
    if (event.packageName == null) return;

    // Filter relevant apps
    final apps = ['com.whatsapp', 'com.facebook.orca', 'com.instagram.android'];
    if (apps.contains(event.packageName)) {
      String message = "New message from ${event.title}: ${event.text}";
      _voice.speak(message);
    }
  }

  static Future<void> startListening() async {
    bool isPermissionGranted = await NotificationsListener.hasPermission ?? false;
    if (!isPermissionGranted) {
      await NotificationsListener.openPermissionSettings();
      return;
    }
    await NotificationsListener.startService();
  }
}
