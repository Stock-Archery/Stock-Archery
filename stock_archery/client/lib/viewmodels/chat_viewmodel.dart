import 'dart:convert';
import 'dart:io';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_config.dart';

// Provider for General Text Analysis
final chatProvider = StateNotifierProvider<ChatViewModel, List<ChatMessage>>((ref) {
  return ChatViewModel(isChart: false);
});

// Provider for Chart Analysis
final chartProvider = StateNotifierProvider<ChatViewModel, List<ChatMessage>>((ref) {
  return ChatViewModel(isChart: true);
});

class ChatViewModel extends StateNotifier<List<ChatMessage>> {
  final bool isChart;
  ChatViewModel({required this.isChart}) : super([]);

  final ChatUser _user = ChatUser(id: '1', firstName: 'User');
  final ChatUser _gemini = ChatUser(
    id: '2', 
    firstName: 'Stock AI',
    profileImage: 'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
  );

  ChatUser get user => _user;
  ChatUser get gemini => _gemini;

  static String get baseUrl => AppConfig.baseUrl;

  void onSend(ChatMessage message, {XFile? imageFile}) async {
    state = [message, ...state];

    try {
      final endpoint = isChart ? '/chart-analysis' : '/chat';
      
      Map<String, dynamic> body = {
        'message': message.text,
      };

      if (isChart && imageFile != null) {
        final bytes = await File(imageFile.path).readAsBytes();
        body['image'] = base64Encode(bytes);
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reply = data['reply'];
        
        final botMessage = ChatMessage(
          text: reply,
          user: _gemini,
          createdAt: DateTime.now(),
        );
        
        state = [botMessage, ...state];
      } else {
        _showError('Error: Server responded with ${response.statusCode}');
      }
    } catch (e) {
      _showError('Connection failed: $e');
    }
  }

  void _showError(String error) {
    final errorMessage = ChatMessage(
      text: error,
      user: _gemini,
      createdAt: DateTime.now(),
    );
    state = [errorMessage, ...state];
  }
}
