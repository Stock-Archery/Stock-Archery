import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert_post.dart';

class AlertsService {
  final String baseUrl;

  AlertsService({required this.baseUrl});

  Future<List<AlertPost>> getAlerts(String category) async {
    final response = await http.get(
      Uri.parse('$baseUrl/alerts/$category'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((a) => AlertPost.fromJson(a)).toList();
    }
    throw Exception('Failed to load alerts');
  }
}
