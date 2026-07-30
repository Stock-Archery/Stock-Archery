import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<bool> broadcast({required String title, required String body}) async {
    final url = '${AppConfig.baseUrl}/broadcast';
    print('[log] POST $url — title: "$title", body: "${body.length > 80 ? body.substring(0, 80) : body}..."');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"title": title, "body": body}),
      );
      print('[log] POST /broadcast — ${response.statusCode}: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('[log] POST /broadcast — error: $e');
      return false;
    }
  }
}
