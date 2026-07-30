import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_config.dart';

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

  // Search user via admin server API
  Future<Map<String, dynamic>?> searchUser(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/search?query=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['user'];
      }
      return null;
    } catch (e) {
      print("Error searching user: $e");
      return null;
    }
  }

  // Update user alert access via admin server API
  Future<bool> updateUserAlertAccess(
    String firebaseUid,
    Map<String, bool> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/users/alert-access/$firebaseUid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating user alert access: $e");
      return false;
    }
  }
}
