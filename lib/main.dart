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
  String _display = 'Tap the mic and say "Check email" or "Calendar"';
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
          _voice.speak("नमस्ते \${account.displayName}! म तपाईंलाई के मद्दत गरूँ?");
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
        _voice.speak("You have new messages. The first one says: \${emails.first}");
        break;
      case 'CHECK_CALENDAR':
        _voice.speak("Checking your calendar.");
        final events = await GoogleService.fetchCalendarEvents();
        _voice.speak("Your upcoming events are: \${events.join(', ')}");
        break;
      case 'ADD_CALENDAR':
        final msg = await GoogleService.createQuickEvent("Meeting from Voice AI");
        _voice.speak(msg);
        break;
      case 'CHECK_DRIVE':
        _voice.speak("Checking your Google Drive.");
        final files = await GoogleService.listDriveFiles();
        _voice.speak("Your recent files are: \${files.join(', ')}");
        break;
      case 'MAKE_CALL':
        _voice.speak("Initiating call.");
        DeviceService.makeCall("9800000000"); 
        break;
      case 'CHECK_TIME':
        _voice.speak("अहिले \${DateTime.now().hour} बजेर \${DateTime.now().minute} मिनेट भएको छ।");
        break;
      default:
        _voice.speak("I am sorry, I did not catch that.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('MeroSathi Voice AI', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (_isUserSignedIn)
            IconButton(icon: const Icon(Icons.logout), onPressed: () => setState(() => _isUserSignedIn = false))
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAnimatedSphere(),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(_display, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
            FloatingActionButton.large(
              onPressed: _onMic,
              backgroundColor: _isListening ? Colors.redAccent : Colors.tealAccent.shade400,
              elevation: 20,
              child: Icon(_isListening ? Icons.stop : Icons.mic, size: 40, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Text(_isUserSignedIn ? (_isListening ? 'LISTENING...' : 'READY') : 'SIGN IN REQUIRED', style: const TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSphere() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: _isListening 
            ? [Colors.cyanAccent.withOpacity(0.8), Colors.teal.withOpacity(0.2), Colors.black]
            : [Colors.teal.withOpacity(0.4), Colors.black],
        ),
        boxShadow: _isListening ? [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
        ] : [],
      ),
      child: Icon(Icons.support_agent, size: 90, color: _isListening ? Colors.cyanAccent : Colors.teal.shade200),
    );
  }
}
