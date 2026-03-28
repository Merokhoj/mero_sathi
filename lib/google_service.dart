import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart' as http;

class GoogleService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      GmailApi.gmailReadonlyScope,
      GmailApi.gmailSendScope,
      CalendarApi.calendarScope,
      DriveApi.driveFileScope,
    ],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      return null;
    }
  }

  static Future<void> signOut() => _googleSignIn.signOut();

  static Future<http.Client?> _getAuthClient() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    final authHeaders = await account.authHeaders;
    return AuthenticatedClient(authHeaders, http.Client());
  }

  static Future<List<String>> fetchEmails() async {
    final client = await _getAuthClient();
    if (client == null) return ["SignIn Required"];
    final gmail = GmailApi(client);
    try {
      final results = await gmail.users.messages.list("me", maxResults: 3);
      if (results.messages == null) return ["No messages found."];
      List<String> snippets = [];
      for (var msg in results.messages!) {
        final detail = await gmail.users.messages.get("me", msg.id!);
        snippets.add(detail.snippet ?? "No snippet");
      }
      return snippets;
    } catch (e) { return ["Error: \$e"]; }
  }

  static Future<List<String>> fetchCalendarEvents() async {
    final client = await _getAuthClient();
    if (client == null) return ["SignIn Required"];
    final calendar = CalendarApi(client);
    try {
      final events = await calendar.events.list("primary", timeMin: DateTime.now().toUtc(), maxResults: 5);
      if (events.items == null || events.items!.isEmpty) return ["No upcoming events."];
      return events.items!.map((e) => "\${e.summary} at \${e.start?.dateTime ?? e.start?.date}").toList();
    } catch (e) { return ["Calendar Error: \$e"]; }
  }

  static Future<String> createQuickEvent(String summary) async {
    final client = await _getAuthClient();
    if (client == null) return "SignIn Required";
    final calendar = CalendarApi(client);
    final event = Event(
      summary: summary,
      start: EventDateTime(dateTime: DateTime.now().add(const Duration(hours: 1)).toUtc()),
      end: EventDateTime(dateTime: DateTime.now().add(const Duration(hours: 2)).toUtc()),
    );
    try {
      await calendar.events.insert(event, "primary");
      return "Event '\$summary' scheduled.";
    } catch (e) { return "Error: \$e"; }
  }

  static Future<List<String>> listDriveFiles() async {
    final client = await _getAuthClient();
    if (client == null) return ["SignIn Required"];
    final drive = DriveApi(client);
    try {
      final fileList = await drive.files.list(pageSize: 5, q: "trashed = false");
      if (fileList.files == null || fileList.files!.isEmpty) return ["No files found."];
      return fileList.files!.map((f) => f.name ?? "Untitled").toList();
    } catch (e) { return ["Drive Error: \$e"]; }
  }
}

class AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;
  AuthenticatedClient(this._headers, this._client);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
