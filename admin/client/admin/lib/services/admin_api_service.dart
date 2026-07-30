import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert_post.dart';
import 'app_config.dart';

class AdminApiService {
  static final AdminApiService _instance = AdminApiService._internal();
  factory AdminApiService() => _instance;
  AdminApiService._internal();

  String get _baseUrl => AppConfig.baseUrl;

  Future<List<AlertPost>> getAlerts(String category) async {
    final response = await http.get(Uri.parse('$_baseUrl/alerts/$category'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List alerts = body['alerts'] ?? [];
      return alerts.map((a) => AlertPost.fromJson(a)).toList();
    }
    throw Exception('Failed to load alerts');
  }

  Future<AlertPost> createAlert(String category, String text, String imageBase64) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/alerts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'category': category,
        'text': text,
        'imageBase64': imageBase64,
      }),
    );

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return AlertPost.fromJson(body['alert']);
    }
    throw Exception('Failed to create alert');
  }

  Future<bool> deleteAlert(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/alerts/$id'));
    return response.statusCode == 200;
  }
}
