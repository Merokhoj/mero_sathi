import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'google_service.dart';
import 'device_service.dart';
import 'voice_assistant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MeroSathiApp());
}

class MeroSathiApp extends StatelessWidget {
  const MeroSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeroSathi Voice AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
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
  String _lastCommand = "नमस्ते! म मेरो साथी, तपाईंलाई के मद्दत गर्न सक्छु?";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initAssistant();
  }

  Future<void> _initAssistant() async {
    await _voice.initialize();
    await DeviceService.requestPermissions();
  }

  void _onListen() async {
    if (!_isListening) {
      bool available = await _voice.initialize();
      if (available) {
        setState(() => _isListening = true);
        _voice.listen((text) {
          setState(() {
            _lastCommand = text;
            _isListening = false;
          });
          _processIntent(text);
        });
      }
    } else {
      setState(() => _isListening = false);
      _voice.stop();
    }
  }

  void _processIntent(String text) {
    // Basic intent mapping for demonstration
    if (text.contains("मेल") || text.contains("email")) {
      _voice.speak("तपाईंसँग ३ वटा इमेलहरू छन्। के तपाईं सुन्न चाहनुहुन्छ?");
    } else if (text.contains("कल") || text.contains("call")) {
      _voice.speak("तपाईं कसलाई फोन गर्न चाहनुहुन्छ?");
    } else if (text.contains("समय") || text.contains("time")) {
      final now = DateTime.now();
      _voice.speak("अहिले $now:hour बजेर $now:minute मिनेट भएको छ।");
    } else {
      _voice.speak("मैले बुझिनँ, फेरि भन्नुहोस्।");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "MeroSathi",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 50),
              _buildPulseIndicator(),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _lastCommand,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
              FloatingActionButton.large(
                onPressed: _onListen,
                backgroundColor: _isListening ? Colors.red : Colors.indigoAccent,
                child: Icon(_isListening ? Icons.stop : Icons.mic, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                _isListening ? "Listening..." : "Tap to speak",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _isListening ? Colors.cyanAccent : Colors.white24,
          width: 2,
        ),
        boxShadow: _isListening
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ]
            : [],
      ),
      child: Icon(
        Icons.support_agent,
        size: 80,
        color: _isListening ? Colors.cyanAccent : Colors.white38,
      ),
    );
  }
}
