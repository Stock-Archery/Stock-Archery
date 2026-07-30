import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_config.dart';

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

  // Search user via admin server API
  Future<Map<String, dynamic>?> searchUser(String query) async {
    final url = '${AppConfig.baseUrl}/users/search?query=${Uri.encodeComponent(query)}';
    print('[log] GET $url');
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final user = body['user'];
        print('[log] GET /users/search — 200: found user ${user?['email']} (${user?['firebaseUid']})');
        return user;
      }
      print('[log] GET /users/search — ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('[log] GET /users/search — error: $e');
      return null;
    }
  }

  // Update user alert access via admin server API
  Future<bool> updateUserAlertAccess(
    String firebaseUid,
    Map<String, bool> updates,
  ) async {
    final url = '${AppConfig.baseUrl}/users/alert-access/$firebaseUid';
    print('[log] PUT $url — body: ${jsonEncode(updates)}');
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
      print('[log] PUT /users/alert-access/$firebaseUid — ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('[log] PUT /users/alert-access/$firebaseUid — error: $e');
      return false;
    }
  }
}
