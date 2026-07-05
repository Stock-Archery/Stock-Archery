import 'dart:io';
import 'package:client/utils/design_system/design_system.dart';
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

class _AiBotViewState extends ConsumerState<AiBotView> with SingleTickerProviderStateMixin {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
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

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepObsidian,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select Image Source",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.goldBright.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.goldBright, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildSegmentedToggle(),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.subtleGrey.withValues(alpha: 0.12)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatView(ref, chatProvider, isChart: false),
                _buildChatView(ref, chartProvider, isChart: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.deepObsidian,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.goldBright.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldBright.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(Icons.gps_fixed_rounded, color: AppColors.goldBright, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ArrowAI",
                style: GoogleFonts.montserrat(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 8),
                  const SizedBox(width: 4),
                  Text(
                    "Online",
                    style: GoogleFonts.inter(
                      color: AppColors.subtleGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 45,
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.subtleGrey.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _tabController.index == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.44,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            children: [
              _buildTabItem("Trading Insights", 0),
              _buildTabItem("Chart Insights", 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.animateTo(index);
          });
        },
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.goldBright : AppColors.subtleGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatView(WidgetRef ref, StateNotifierProvider<ChatViewModel, ChatState> provider, {required bool isChart}) {
    final chatState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Column(
      children: [
        Expanded(
          child: chatState.messages.isEmpty && !chatState.isLoading
            ? _buildWelcomeScreen(isChart)
            : _buildMessageList(chatState.messages, viewModel, isChart, isLoading: chatState.isLoading),
        ),
        _buildInputArea(viewModel, isChart),
      ],
    );
  }

  Widget _buildWelcomeScreen(bool isChart) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.pureBlack,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.goldBright.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.gps_fixed_rounded, color: AppColors.goldBright, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              "ArrowAI by Stock Archery",
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isChart 
                ? "Upload any chart — I'll read the price action, key levels, candles & patterns for you."
                : "Ask me anything about stock markets, finance, or trading strategies.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.subtleGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: isChart 
                ? [
                    _buildActionTile(Icons.bar_chart, "Analyse this chart"),
                    _buildActionTile(Icons.line_axis, "Support & Resistance"),
                    _buildActionTile(Icons.shape_line, "Identify Patterns"),
                    _buildActionTile(Icons.bolt, "Breakout Targets"),
                  ]
                : [
                    _buildActionTile(Icons.insights, "What is Nifty 50?"),
                    _buildActionTile(Icons.newspaper, "Latest Market News"),
                    _buildActionTile(Icons.trending_up, "Top Gainers Today"),
                    _buildActionTile(Icons.monetization_on, "Best Penny Stocks"),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.goldBright),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, ChatViewModel viewModel, bool isChart, {bool isLoading = false}) {
    return DashChat(
      currentUser: viewModel.user,
      onSend: (_) {}, // Handled by our custom input
      messages: messages,
      readOnly: true,
      messageOptions: MessageOptions(
        showOtherUsersAvatar: true,
        showTime: true,
        containerColor: AppColors.pureBlack,
        textColor: AppColors.onSurface,
        currentUserContainerColor: AppColors.goldBright,
        currentUserTextColor: AppColors.deepObsidian,
        messageDecorationBuilder: (message, previousMessage, nextMessage) {
          final isUser = message.user.id == viewModel.user.id;
          return BoxDecoration(
            color: isUser ? AppColors.goldBright : AppColors.pureBlack,
            borderRadius: BorderRadius.circular(16),
            border: isUser
                ? null
                : Border.all(
                    color: AppColors.goldBright.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
          );
        },
        messageTextBuilder: (message, previousMessage, nextMessage) {
          final isUser = message.user.id == viewModel.user.id;
          return MarkdownBody(
            data: message.text,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.inter(
                fontSize: 15,
                color: isUser ? AppColors.deepObsidian : AppColors.onSurface,
              ),
              strong: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isUser ? AppColors.deepObsidian : AppColors.onSurface,
              ),
              listBullet: GoogleFonts.inter(
                fontSize: 15,
                color: isUser ? AppColors.deepObsidian : AppColors.onSurface,
              ),
            ),
          );
        },
      ),
      typingUsers: isLoading ? [viewModel.gemini] : [],
    );
  }

  Widget _buildInputArea(ChatViewModel viewModel, bool isChart) {
    final TextEditingController controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.deepObsidian,
        border: Border(
          top: BorderSide(
            color: AppColors.subtleGrey.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (isChart && _selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_selectedImage!.path), height: 80, width: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.error, size: 20),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.pureBlack,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.goldBright.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isChart)
                        IconButton(
                          icon: const Icon(Icons.file_upload_outlined, color: AppColors.goldBright),
                          onPressed: _showImagePickerOptions,
                        ),
                      if (!isChart) const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Ask anything about stocks & charts...",
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.subtleGrey.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            if (controller.text.isEmpty) return;
                            if (isChart && _selectedImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please upload a chart image first!")),
                              );
                              return;
                            }
                            final message = ChatMessage(
                              text: controller.text,
                              user: viewModel.user,
                              createdAt: DateTime.now(),
                            );
                            viewModel.onSend(message, imageFile: isChart ? _selectedImage : null);
                            if (isChart) setState(() => _selectedImage = null);
                            controller.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.goldBright,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.send_rounded, color: AppColors.deepObsidian, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Stock Archery • ArrowAI — No buy/sell signals. Observation only.",
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.subtleGrey.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
