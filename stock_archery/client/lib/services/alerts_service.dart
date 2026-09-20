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
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      // Safety net: server already filters to last 7 days, but drop any
      // stale items that slip through (clock skew / cached responses).
      return data
          .map((a) => AlertPost.fromJson(a))
          .where((a) => !a.createdAt.isBefore(cutoff))
          .toList();
    }
    throw Exception('Failed to load alerts');
  }
}
