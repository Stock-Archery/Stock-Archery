import 'dart:io';
import 'package:client/viewmodels/chat_viewmodel.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AiBotView extends ConsumerStatefulWidget {
  const AiBotView({super.key});

  @override
  ConsumerState<AiBotView> createState() => _AiBotViewState();
}

class _AiBotViewState extends ConsumerState<AiBotView> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Stock Archery AI",
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: const Color(0xFF6366F1),
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Text Analysis"),
              Tab(text: "Chart Analysis"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatView(ref, chatProvider, isChart: false),
            _buildChatView(ref, chartProvider, isChart: true),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(WidgetRef ref, StateNotifierProvider<ChatViewModel, List<ChatMessage>> provider, {required bool isChart}) {
    final messages = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Column(
      children: [
        if (isChart && _selectedImage != null)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_selectedImage!.path),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: DashChat(
            currentUser: viewModel.user,
            onSend: (ChatMessage message) {
              if (isChart && _selectedImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please upload a chart image first!")),
                );
                return;
              }
              viewModel.onSend(message, imageFile: isChart ? _selectedImage : null);
              if (isChart) setState(() => _selectedImage = null);
            },
            messages: messages,
            inputOptions: InputOptions(
              leading: isChart 
                ? [
                    IconButton(
                      icon: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF6366F1)),
                      onPressed: _pickImage,
                    ),
                  ]
                : [],
              inputDecoration: InputDecoration(
                hintText: isChart ? "Describe the chart..." : "Ask anything about stocks...",
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
                final isUser = message.user.id == viewModel.user.id;
                return MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.inter(
                      fontSize: 15,
                      color: isUser ? Colors.black : Colors.white,
                    ),
                    strong: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isUser ? Colors.black : Colors.white,
                    ),
                    a: GoogleFonts.inter(
                      fontSize: 15,
                      color: isUser ? Colors.blue : Colors.blueAccent[100],
                      decoration: TextDecoration.underline,
                    ),
                    listBullet: GoogleFonts.inter(
                      fontSize: 15,
                      color: isUser ? Colors.black : Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
