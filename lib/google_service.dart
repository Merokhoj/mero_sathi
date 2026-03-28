import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class GoogleService {
  static const String _serverClientId = "474518514090-a96kkkgd38n57gl91ksg0afle65rgjur.apps.googleusercontent.com";
  
  static const List<String> _scopes = [
    GmailApi.gmailReadonlyScope,
    GmailApi.gmailSendScope,
    CalendarApi.calendarScope,
    DriveApi.driveFileScope,
  ];

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static GoogleSignInAccount? _user;

  static Future<void> initialize() async {
    try {
      // In version 7.2.0+, we MUST initialize with the serverClientId
      await _googleSignIn.initialize(
        serverClientId: _serverClientId,
      );
      
      // Attempt to sign in silently
      _user = await _googleSignIn.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint("Google Service Init Error: $e");
    }
  }

  static bool get isSignedIn => _user != null;

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // In version 7.2.0+, use authenticate() instead of signIn()
      final account = await _googleSignIn.authenticate();
      _user = account;
      return account;
    } catch (error) {
      debugPrint("Sign In Error: $error");
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
  }

  /// Helper to get authorization headers with requested scopes
  static Future<Map<String, String>?> _getAuthHeaders() async {
    if (_user == null) return null;
    
    // In version 7.2.0+, use authorizationClient to get headers for specific scopes
    return await _user!.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );
  }

  static Future<List<String>> fetchEmails() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return ["SignIn Required"];

    try {
      final client = _GoogleAuthClient(headers);
      final gmail = GmailApi(client);
      final response = await gmail.users.messages.list("me", maxResults: 5);
      
      if (response.messages == null || response.messages!.isEmpty) {
        return ["No emails found"];
      }

      List<String> snippets = [];
      for (var msg in response.messages!) {
        final detail = await gmail.users.messages.get("me", msg.id!);
        snippets.add(detail.snippet ?? "No content");
      }
      return snippets;
    } catch (e) {
      debugPrint("Gmail Error: $e");
      return ["Error fetching emails: $e"];
    }
  }

  static Future<List<String>> fetchCalendarEvents() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return ["SignIn Required"];

    try {
      final client = _GoogleAuthClient(headers);
      final calendar = CalendarApi(client);
      final response = await calendar.events.list("primary", timeMin: DateTime.now().toUtc(), maxResults: 5);
      
      if (response.items == null || response.items!.isEmpty) {
        return ["No upcoming events"];
      }

      return response.items!.map((e) => "${e.summary} (${e.start?.dateTime ?? e.start?.date})").toList();
    } catch (e) {
      debugPrint("Calendar Error: $e");
      return ["Error fetching events"];
    }
  }

  static Future<String> createQuickEvent(String title) async {
    final headers = await _getAuthHeaders();
    if (headers == null) return "SignIn Required";

    try {
      final client = _GoogleAuthClient(headers);
      final calendar = CalendarApi(client);
      final event = Event(
        summary: title,
        start: EventDateTime(dateTime: DateTime.now().add(const Duration(hours: 1)).toUtc()),
        end: EventDateTime(dateTime: DateTime.now().add(const Duration(hours: 2)).toUtc()),
      );

      await calendar.events.insert(event, "primary");
      return "कार्यक्रम $title थपियो!";
    } catch (e) {
      return "क्यालेन्डरमा समस्या आयो।";
    }
  }

  static Future<List<String>> listDriveFiles() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return ["SignIn Required"];

    try {
      final client = _GoogleAuthClient(headers);
      final drive = DriveApi(client);
      final response = await drive.files.list(pageSize: 5);
      
      if (response.files == null || response.files!.isEmpty) {
        return ["No files in Drive"];
      }

      return response.files!.map((f) => "${f.name} (${f.mimeType})").toList();
    } catch (e) {
      return ["Drive Error: $e"];
    }
  }
}

class _GoogleAuthClient extends BaseClient {
  final Map<String, String> _headers;
  final Client _client = Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

