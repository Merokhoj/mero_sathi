import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'google_service.dart';
import 'device_service.dart';
import 'voice_assistant.dart';
import 'ai_service.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await GoogleService.initialize();
  } catch (e) {
    debugPrint("Firebase/Google Init Error: $e");
  }
  await NotificationService.initialize();
  runApp(const MeroSathiApp());
}

class MeroSathiApp extends StatelessWidget {
  const MeroSathiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeroSathi Voice AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent, 
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        textTheme: const TextTheme(
          displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
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
  final AIService _ai = AIService();
  String _display = 'Tap the mic and say "Check email" or "Calendar"';
  bool _isListening = false;
  bool _isUserSignedIn = false;

  @override
  void initState() {
    super.initState();
    _voice.initialize();
    DeviceService.requestPermissions();
    // Check initial sign-in status
    setState(() {
      _isUserSignedIn = GoogleService.isSignedIn;
    });
  }

  void _onMic() async {
    if (!_isUserSignedIn) {
      final account = await GoogleService.signIn();
      if (account != null) {
        if (!mounted) return;
        setState(() => _isUserSignedIn = true);
        _voice.speak("नमस्ते ${account.displayName}! म तपाईंलाई के मद्दत गरूँ?");
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Sign In Failed. Please check your Google Cloud configuration (Web Client ID)."),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(label: "HELP", textColor: Colors.white, onPressed: () {
              // Inform the user about the Web Client ID requirement
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Configuration Error"),
                  content: const Text("The Google Sign-In plugin requires a 'Web Client ID' to authorize Gmail and Calendar access. Please update your google_service.dart with your Web Client ID from the Google Cloud Console."),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
                ),
              );
            }),
          ),
        );
      }
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);
      await _voice.listen((text) {
        setState(() { 
          _display = text; 
          _isListening = false; 
        });
        _handleIntent(text);
      });
    } else {
      _voice.stop();
      setState(() => _isListening = false);
    }
  }

  void _handleIntent(String text) async {
    setState(() => _display = "प्रक्रिया गर्दै..."); // Processing...
    final intent = await _ai.processVoiceCommand(text);
    
    switch (intent.action) {
      case 'SEND_EMAIL':
        _voice.speak("तपाईंका इमेलहरू खोज्दैछु।");
        final emails = await GoogleService.fetchEmails();
        if (emails.first == "SignIn Required") {
           _voice.speak("कृपया पहिले गुगलमा साइन इन गर्नुहोस्।");
           _onMic();
        } else {
           _voice.speak("तपाईंसँग नयाँ सन्देशहरू छन्। पहिलो सन्देशमा भनिएको छ: ${emails.isNotEmpty ? emails.first : 'कुनै सन्देश छैन'}");
        }
        break;
      case 'CHECK_CALENDAR':
        _voice.speak("तपाईंको क्यालेन्डर जाँच गर्दैछु।");
        final events = await GoogleService.fetchCalendarEvents();
        if (events.first == "SignIn Required") {
           _voice.speak("कृपया पहिले गुगलमा साइन इन गर्नुहोस्।");
           _onMic();
        } else {
           _voice.speak("तपाईंका आगामी कार्यक्रमहरू: ${events.join(', ')}");
        }
        break;
      case 'ADD_CALENDAR':
        final title = intent.params['title'] ?? "MeroSathi Reminder";
        final msg = await GoogleService.createQuickEvent(title);
        _voice.speak(msg);
        break;
      case 'CHECK_DRIVE':
        _voice.speak("तपाईंको गुगल ड्राइभ हेर्दैछु।");
        final files = await GoogleService.listDriveFiles();
        if (files.first == "SignIn Required") {
           _voice.speak("कृपया पहिले गुगलमा साइन इन गर्नुहोस्।");
           _onMic();
        } else {
           _voice.speak("ड्राइभका फाइलहरू: ${files.join(', ')}");
        }
        break;
      case 'MAKE_CALL':
        final name = intent.params['name'] ?? "अनजान";
        _voice.speak("$name लाई कल गर्दैछु।");
        DeviceService.makeCall("9800000000"); 
        break;
      case 'CHECK_TIME':
        _voice.speak("अहिले ${DateTime.now().hour} बजेर ${DateTime.now().minute} मिनेट भएको छ।");
        break;
      default:
        _voice.speak("माफ गर्नुहोस्, मैले बुझिन। फेरि भन्नुहोस्।");
    }
    setState(() => _display = "READY");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient with Mesh Effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF001A1A),
                    const Color(0xFF000808),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Floating Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAnimatedSphere(),
                            const SizedBox(height: 60),
                            _buildDisplayCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildMicButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MeroSathi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(colors: [Colors.tealAccent, Colors.cyanAccent]),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (_isUserSignedIn) ...[
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined, color: Colors.tealAccent),
                  onPressed: () => NotificationService.startListening(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                  onPressed: () async {
                    await GoogleService.signOut();
                    setState(() => _isUserSignedIn = false);
                  },
                ),
              ] else 
                TextButton.icon(
                  onPressed: _onMic,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.tealAccent, size: 24),
          const SizedBox(height: 16),
          Text(
            _display, 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontSize: 20, 
              height: 1.6,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _onMic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_isListening),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.redAccent : Colors.tealAccent).withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening 
                      ? [Colors.redAccent, Colors.orangeAccent] 
                      : [const Color(0xFF00BFA5), Colors.cyanAccent],
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded, 
                  size: 52, 
                  color: Colors.black
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.redAccent : Colors.tealAccent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isUserSignedIn ? (_isListening ? 'LISTENING NOW' : 'TAP TO TALK') : 'SIGN IN REQUIRED', 
              style: const TextStyle(
                letterSpacing: 3, 
                fontSize: 12, 
                fontWeight: FontWeight.w800, 
                color: Colors.white38
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedSphere() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: _isListening 
            ? [Colors.cyanAccent.withValues(alpha: 0.6), Colors.teal.withValues(alpha: 0.1), Colors.black]
            : [Colors.tealAccent.withValues(alpha: 0.2), Colors.black],
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
             // Dynamic Ring
             AnimatedContainer(
               duration: const Duration(seconds: 1),
               width: _isListening ? 200 : 160,
               height: _isListening ? 200 : 160,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 border: Border.all(
                   color: (_isListening ? Colors.cyanAccent : Colors.tealAccent).withValues(alpha: 0.3),
                   width: 2,
                 ),
               ),
             ),
             Icon(
               _isListening ? Icons.graphic_eq : Icons.support_agent, 
               size: 100, 
               color: _isListening ? Colors.cyanAccent : Colors.tealAccent.withValues(alpha: 0.7)
             ),
          ],
        ),
      ),
    );
  }
}
