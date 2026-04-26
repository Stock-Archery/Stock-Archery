import 'package:client/viewmodels/chat_viewmodel.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AiBotView extends ConsumerWidget {
  const AiBotView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
    final viewModel = ref.read(chatProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Stock Archery AI",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DashChat(
        currentUser: viewModel.user,
        onSend: viewModel.onSend,
        messages: messages,
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: "Ask anything about stocks...",
            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          sendButtonBuilder: (onSend) => IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFF6366F1)),
            onPressed: onSend,
          ),
        ),
        messageOptions: MessageOptions(
          showOtherUsersAvatar: true,
          showTime: true,
          containerColor: const Color(0xFF6366F1),
          textColor: Colors.white,
          currentUserContainerColor: Colors.grey[200],
          currentUserTextColor: Colors.black,
          messageTextBuilder: (message, previousMessage, nextMessage) {
            return Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: message.user.id == viewModel.user.id ? Colors.black : Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
