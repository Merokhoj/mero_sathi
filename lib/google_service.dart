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
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  static Future<void> signOut() => _googleSignIn.signOut();

  static Future<http.Client?> getAuthenticatedClient() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    return AuthenticatedClient(authHeaders, http.Client());
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
