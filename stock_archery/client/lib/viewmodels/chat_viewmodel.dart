import 'dart:convert';
import 'dart:io';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_config.dart';
import 'auth_viewmodel.dart';

// Longest message the input accepts. The server rejects anything longer, so
// keep this in sync with MAX_MESSAGE_LENGTH in server chatController.js.
const int kMaxChatMessageLength = 2000;

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  // One-shot signal: the server just returned a 403 limitReached response.
  // The view listens for this flipping to true, shows the premium dialog,
  // then calls clearLimitReached() to reset it.
  final bool limitReached;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.limitReached = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? limitReached,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      limitReached: limitReached ?? this.limitReached,
    );
  }
}

// Provider for General Text Analysis.
// Watching the logged-in user's id makes this rebuild (and reload that
// user's saved history from the server) whenever the account changes, so one
// account's chat can never carry over into another's.
final chatProvider = StateNotifierProvider<ChatViewModel, ChatState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.firebaseUid));
  return ChatViewModel(isChart: false)..loadHistory();
});

// Provider for Chart Analysis (same per-account rebuild as above)
final chartProvider = StateNotifierProvider<ChatViewModel, ChatState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.firebaseUid));
  return ChatViewModel(isChart: true)..loadHistory();
});

class ChatViewModel extends StateNotifier<ChatState> {
  final bool isChart;
  ChatViewModel({required this.isChart}) : super(const ChatState());

  // History paging: the server returns newest-first pages; the cursor is the
  // createdAt of the oldest message loaded so far.
  bool _isLoadingHistory = false;
  bool _hasMoreHistory = false;
  DateTime? _oldestCreatedAt;

  final ChatUser _user = ChatUser(id: '1', firstName: 'User');
  final ChatUser _gemini = ChatUser(
    id: '2',
    firstName: 'Stock AI',
    profileImage: 'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
  );

  ChatUser get user => _user;
  ChatUser get gemini => _gemini;

  static String get baseUrl => AppConfig.baseUrl;

  ChatMessage _messageFromJson(Map<String, dynamic> m) {
    final imageUrl = m['imageUrl'] as String?;
    return ChatMessage(
      text: m['text'] as String? ?? '',
      user: m['role'] == 'user' ? _user : _gemini,
      createdAt: DateTime.parse(m['createdAt'] as String).toLocal(),
      medias: imageUrl == null
          ? null
          : [ChatMedia(url: imageUrl, fileName: 'chart.jpg', type: MediaType.image)],
    );
  }

  Future<Map<String, dynamic>?> _fetchHistoryPage({DateTime? before}) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return null;

    final uri = Uri.parse('$baseUrl/chat/history').replace(queryParameters: {
      'type': isChart ? 'chart' : 'text',
      'limit': '30',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    });
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      debugPrint('[ChatViewModel] history fetch failed: ${response.statusCode}');
      return null;
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Loads the latest page of this thread's saved history. A failure just
  /// leaves the chat empty — it never blocks sending.
  Future<void> loadHistory() async {
    if (_isLoadingHistory) return;
    _isLoadingHistory = true;
    try {
      final data = await _fetchHistoryPage();
      if (data == null || !mounted) return;
      // The user already sent something while this was loading: skip, rather
      // than risk showing the same messages twice.
      if (state.messages.isNotEmpty) return;

      final page = (data['messages'] as List).cast<Map<String, dynamic>>();
      _hasMoreHistory = data['hasMore'] == true;
      if (page.isNotEmpty) {
        _oldestCreatedAt = DateTime.parse(page.last['createdAt'] as String);
      }
      state = state.copyWith(messages: page.map(_messageFromJson).toList());
    } catch (e) {
      debugPrint('[ChatViewModel] loadHistory failed: $e');
    } finally {
      _isLoadingHistory = false;
    }
  }

  /// Deletes this thread's saved history on the server, then empties the list.
  /// Returns false, leaving the chat untouched, if the server call fails.
  Future<bool> clearHistory() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return false;

      final uri = Uri.parse('$baseUrl/chat/history').replace(queryParameters: {
        'type': isChart ? 'chart' : 'text',
      });
      final response = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[ChatViewModel] clearHistory failed: ${response.statusCode}');
        return false;
      }
      if (!mounted) return true;

      _hasMoreHistory = false;
      _oldestCreatedAt = null;
      state = state.copyWith(messages: const []);
      return true;
    } catch (e) {
      debugPrint('[ChatViewModel] clearHistory failed: $e');
      return false;
    }
  }

  /// Loads the next older page. Wired to dash_chat_2's onLoadEarlier, which
  /// fires when the user scrolls to the top of the list.
  Future<void> loadEarlier() async {
    if (_isLoadingHistory || !_hasMoreHistory || _oldestCreatedAt == null) return;
    _isLoadingHistory = true;
    try {
      final data = await _fetchHistoryPage(before: _oldestCreatedAt);
      if (data == null || !mounted) return;

      final page = (data['messages'] as List).cast<Map<String, dynamic>>();
      _hasMoreHistory = data['hasMore'] == true;
      if (page.isNotEmpty) {
        _oldestCreatedAt = DateTime.parse(page.last['createdAt'] as String);
        state = state.copyWith(
          messages: [...state.messages, ...page.map(_messageFromJson)],
        );
      }
    } catch (e) {
      debugPrint('[ChatViewModel] loadEarlier failed: $e');
    } finally {
      _isLoadingHistory = false;
    }
  }

  void onSend(ChatMessage message, {XFile? imageFile, required bool isPremium}) async {
    state = state.copyWith(
      messages: [message, ...state.messages],
      isLoading: true,
    );

    try {
      final endpoint = isChart ? '/chart-analysis' : '/chat';
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      Map<String, dynamic> body = {
        'message': message.text,
        'isPremium': isPremium,
      };

      if (isChart && imageFile != null) {
        final bytes = await File(imageFile.path).readAsBytes();
        body['image'] = base64Encode(bytes);
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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

        state = state.copyWith(
          messages: [botMessage, ...state.messages],
          isLoading: false,
        );
      } else if (response.statusCode == 400) {
        // e.g. a chart follow-up when no chart is stored yet: show the
        // server's explanation rather than a bare status code.
        final data = json.decode(response.body);
        _showError(data['message']?.toString() ?? 'Invalid request');
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        if (data['limitReached'] == true) {
          // Surface this as the premium dialog (via the view's ref.listen),
          // not a chat bubble — no message was actually sent.
          state = state.copyWith(isLoading: false, limitReached: true);
        } else {
          _showError('Error: ${data['message']}');
        }
      } else {
        _showError('Error: Server responded with ${response.statusCode}');
      }
    } catch (e) {
      _showError('Connection failed: $e');
    }
  }

  void clearLimitReached() {
    state = state.copyWith(limitReached: false);
  }

  void _showError(String error) {
    final errorMessage = ChatMessage(
      text: error,
      user: _gemini,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [errorMessage, ...state.messages],
      isLoading: false,
    );
  }
}
