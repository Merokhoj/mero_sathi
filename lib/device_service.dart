import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class DeviceService {
  static final Telephony _telephony = Telephony.instance;

  static Future<bool> requestPermissions() async {
    final status = await [
      Permission.contacts,
      Permission.phone,
      Permission.sms,
      Permission.microphone,
      Permission.notification,
    ].request();

    return status.values.every((element) => element.isGranted);
  }

  static Future<void> sendSms(String number, String message) async {
    try {
      await _telephony.sendSms(to: number, message: message);
    } catch (e) {
      print('Sms Error: $e');
    }
  }

  static Future<void> makeCall(String number) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$number',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }

  static Future<void> setAlarm(int hour, int minute, String message) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.MESSAGE': message,
        'android.intent.extra.alarm.SKIP_UI': true,
      },
    );
    await intent.launch();
  }
}
