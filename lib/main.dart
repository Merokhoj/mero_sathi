import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'google_service.dart';
import 'device_service.dart';
import 'voice_assistant.dart';
import 'ai_intent_processor.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  runApp(const MeroSathiApp());
}

class MeroSathiApp extends StatelessWidget {
  const MeroSathiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeroSathi Voice AI',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark)),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final VoiceAssistant _voice = VoiceAssistant();
  String _display = 'Tap the mic and say "Check email" or "Call someone"';
  bool _isListening = false;
  bool _isUserSignedIn = false;

  @override
  void initState() {
    super.initState();
    _voice.initialize();
    DeviceService.requestPermissions();
  }

  void _onMic() async {
    if (!_isListening) {
      if (!_isUserSignedIn) {
        final account = await GoogleService.signIn();
        if (account != null) {
          setState(() => _isUserSignedIn = true);
          _voice.speak("नमस्ते ${account.displayName}! म तपाईंलाई के मद्दत गरूँ?");
        }
        return;
      }

      setState(() => _isListening = true);
      await _voice.listen((text) {
        setState(() { _display = text; _isListening = false; });
        _handleIntent(text);
      });
    } else {
      _voice.stop();
      setState(() => _isListening = false);
    }
  }

  void _handleIntent(String text) async {
    final intent = AIIntentProcessor.parse(text);
    switch (intent.action) {
      case 'SEND_EMAIL':
        _voice.speak("Fetching your recent emails.");
        final emails = await GoogleService.fetchEmails();
        _voice.speak("You have ${emails.length} new messages. The first one says: ${emails.first}");
        break;
      case 'MAKE_CALL':
        _voice.speak("Initiating call.");
        DeviceService.makeCall("9800000000"); // Demo number
        break;
      case 'SEND_SMS':
        _voice.speak("Sending SMS.");
        DeviceService.sendSms("9800000000", "Hello from MeroSathi AI!");
        break;
      case 'CHECK_TIME':
        _voice.speak("अहिले ${DateTime.now().hour} बजेर ${DateTime.now().minute} मिनेट भएको छ।");
        break;
      default:
        _voice.speak("I am sorry, I did not catch that. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeroSathi Voice AI'),
        actions: [
          if (_isUserSignedIn)
            IconButton(icon: const Icon(Icons.logout), onPressed: () => setState(() => _isUserSignedIn = false))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 100, color: Colors.tealAccent),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_display, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white70)),
            ),
            const SizedBox(height: 50),
            FloatingActionButton.large(
              onPressed: _onMic,
              backgroundColor: _isListening ? Colors.red : Colors.tealAccent,
              child: Icon(_isListening ? Icons.stop : Icons.mic, size: 40)
            ),
            const SizedBox(height: 20),
            Text(_isUserSignedIn ? (_isListening ? 'Assistant is listening...' : 'Say something...') : 'Tap to Sign in with Google')
          ],
        ),
      ),
    );
  }
}
