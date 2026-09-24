import 'dart:async';
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
    print('[log] GET $_baseUrl/alerts/$category');
    final response = await http.get(Uri.parse('$_baseUrl/alerts/$category'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List alerts = body['alerts'] ?? [];
      print('[log] GET /alerts/$category — 200: ${alerts.length} alerts loaded');
      return alerts.map((a) => AlertPost.fromJson(a)).toList();
    }
    print('[log] GET /alerts/$category — ${response.statusCode}: ${response.body}');
    throw Exception('Failed to load alerts');
  }

  /// Creates an alert. The image (if any) is sent as base64 only in transit:
  /// the server uploads it to ImageKit and stores just the link.
  /// Throws an Exception whose message is safe to show the admin.
  Future<AlertPost> createAlert(String category, String text, String? imageBase64) async {
    print('[log] POST $_baseUrl/alerts — category: $category, text: ${text.substring(0, text.length > 50 ? 50 : text.length)}..., image: ${imageBase64 != null}');

    final http.Response response;
    try {
      // Generous timeout: the server uploads the image to ImageKit before it replies.
      response = await http
          .post(
            Uri.parse('$_baseUrl/alerts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'category': category,
              'text': text,
              if (imageBase64 != null) 'imageBase64': imageBase64,
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw Exception('The upload timed out. Check your connection and try again.');
    }

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      print('[log] POST /alerts — 201: alert created, id: ${body['alert']['_id']}');
      return AlertPost.fromJson(body['alert']);
    }
    print('[log] POST /alerts — ${response.statusCode}: ${response.body}');

    // The server explains itself (e.g. image too large, storage not configured).
    var message = 'Failed to create alert';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) message = body['message'];
    } catch (_) {}
    throw Exception(message);
  }

  Future<bool> deleteAlert(String id) async {
    print('[log] DELETE $_baseUrl/alerts/$id');
    final response = await http.delete(Uri.parse('$_baseUrl/alerts/$id'));
    print('[log] DELETE /alerts/$id — ${response.statusCode}');
    return response.statusCode == 200;
  }
}
