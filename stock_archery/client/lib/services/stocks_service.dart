import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_config.dart';

class StocksService {
  static final StocksService _instance = StocksService._internal();
  factory StocksService() => _instance;
  StocksService._internal();

  static String get baseUrl => AppConfig.baseUrl;

  Future<List<String>> getRecommendations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recommendations'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<String>.from(data);
      } else {
        throw Exception("Failed to load recommendations: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error connecting to server: $e");
    }
  }
}
