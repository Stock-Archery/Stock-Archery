import 'dart:convert';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final chatProvider = StateNotifierProvider<ChatViewModel, List<ChatMessage>>((ref) {
  return ChatViewModel();
});

class ChatViewModel extends StateNotifier<List<ChatMessage>> {
  ChatViewModel() : super([]);

  final ChatUser _user = ChatUser(id: '1', firstName: 'User');
  final ChatUser _gemini = ChatUser(
    id: '2', 
    firstName: 'Stock AI',
    profileImage: 'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
  );

  ChatUser get user => _user;
  ChatUser get gemini => _gemini;

  static String get baseUrl => dotenv.get('BASE_URL', fallback: 'http://172.24.224.1:5000/api');

  void onSend(ChatMessage message) async {
    state = [message, ...state];

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message.text}),
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
