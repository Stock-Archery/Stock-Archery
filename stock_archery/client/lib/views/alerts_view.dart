import 'dart:convert';
import 'package:client/models/alert_post.dart';
import 'package:client/models/video_model.dart';
import 'package:client/utils/design_system/design_system.dart';
import 'package:client/viewmodels/alerts_provider.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:client/Features/payment/view_model/premium_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AlertsView extends ConsumerWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final user = ref.watch(authProvider).user;
    final isSuperPremium = ref.watch(premiumProvider).superPremium;

    bool isCategoryLocked(String category) {
      if (isSuperPremium) return false;
      return switch (category) {
        'SOB' => user?.isSOBAlertPremium != true,
        'XAUD' => user?.isXaudAlertPremium != true,
        'Crypto' => user?.isCryptoAlertPremium != true,
        _ => true,
      };
    }

    final isLocked = isCategoryLocked(selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      body: Column(
        children: [
          // Category tabs
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerMarginMobile,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: ['SOB', 'XAUD', 'Crypto'].map((cat) {
                final isSelected = selectedCategory == cat;
                final locked = isCategoryLocked(cat);
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = cat;
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.goldBright
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadii.base),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.goldBright
                              : AppColors.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (locked) ...[
                            Icon(
                              Icons.lock_outline,
                              size: 13,
                              color: isSelected
                                  ? AppColors.pureBlack
                                  : AppColors.subtleGrey,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            cat,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? AppColors.pureBlack
                                  : AppColors.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: AppColors.subtleGrey.withValues(alpha: 0.12),
          ),

          // Content
          Expanded(
            child: isLocked
                ? _buildLockedState(context, selectedCategory)
                : _AlertFeed(category: selectedCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState(BuildContext context, String category) {
    final introVideo = _categoryIntroVideos[category];
    final freeAccessVideo = _categoryFreeAccessVideos[category];

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldBright.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.goldBright.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.goldBright,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Unlock $category Alerts',
                style: GoogleFonts.montserrat(
                  color: AppColors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Contact support to get premium access for $category alerts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              if (introVideo != null) ...[
                const SizedBox(height: AppSpacing.xl),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: AppColors.pureBlack.withValues(alpha: 0.8),
                      builder: (context) =>
                          _VideoPopupDialog(video: introVideo),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.metallicGold.withValues(alpha: 0.15),
                          AppColors.goldBright.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.base),
                      border: Border.all(
                        color: AppColors.goldBright.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: AppColors.goldBright,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Click to know about $category alerts',
                          style: GoogleFonts.inter(
                            color: AppColors.goldBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (freeAccessVideo != null) ...[
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: AppColors.pureBlack.withValues(alpha: 0.8),
                      builder: (context) =>
                          _VideoPopupDialog(video: freeAccessVideo),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.metallicGold.withValues(alpha: 0.15),
                          AppColors.goldBright.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.base),
                      border: Border.all(
                        color: AppColors.goldBright.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: AppColors.goldBright,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Want free access of $category alerts?',
                          style: GoogleFonts.inter(
                            color: AppColors.goldBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final Map<String, VideoModel> _categoryIntroVideos = {
  'SOB': VideoModel(
    title: 'About SOB Alerts',
    videoId: 'VHg3TFRsUME',
    thumbnail: 'https://img.youtube.com/vi/VHg3TFRsUME/0.jpg',
    description:
        'Learn how to use SOB alerts for trading and maximize your profits.',
  ),
  'XAUD': VideoModel(
    title: 'About XAUD Alerts',
    videoId: 'e1AkQf36duw',
    thumbnail: 'https://img.youtube.com/vi/e1AkQf36duw/0.jpg',
    description: 'Learn how to use XAUD alerts for gold trading.',
  ),
  'Crypto': VideoModel(
    title: 'About Crypto Alerts',
    videoId: 'bDLYO5D7RoE',
    thumbnail: 'https://img.youtube.com/vi/bDLYO5D7RoE/0.jpg',
    description: 'Learn how to use Crypto alerts for digital asset trading.',
  ),
};

final Map<String, VideoModel> _categoryFreeAccessVideos = {
  'SOB': VideoModel(
    title: 'How to get free SOB Alerts',
    videoId:
        'E1vwRZdTkvg', // Replace with user's specific video ID if different
    thumbnail: 'https://img.youtube.com/vi/E1vwRZdTkvg/0.jpg',
    description: 'Learn how to get free access to SOB alerts.',
  ),
  'XAUD': VideoModel(
    title: 'How to get free XAUD Alerts',
    videoId:
        'u5TIlHaGxUs', // Replace with user's specific video ID if different
    thumbnail: 'https://img.youtube.com/vi/u5TIlHaGxUs/0.jpg',
    description: 'Learn how to get free access to XAUD alerts.',
  ),
  'Crypto': VideoModel(
    title: 'How to get free Crypto Alerts',
    videoId:
        'bDLYO5D7RoE', // Replace with user's specific video ID if different
    thumbnail: 'https://img.youtube.com/vi/bDLYO5D7RoE/0.jpg',
    description: 'Learn how to get free access to Crypto alerts.',
  ),
};

class _AlertFeed extends ConsumerWidget {
  final String category;

  const _AlertFeed({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider(category));

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  color: AppColors.subtleGrey,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No alerts yet',
                  style: GoogleFonts.inter(
                    color: AppColors.subtleGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force sync profile settings on manual pull-to-refresh to pull latest database values
            await ref.read(authProvider.notifier).syncProfile();
            ref.invalidate(alertsProvider(category));
          },
          color: AppColors.goldBright,
          backgroundColor: AppColors.pureBlack,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerMarginMobile,
              vertical: AppSpacing.md,
            ),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final post = alerts[index];
              return _AlertPostCard(post: post);
            },
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(color: AppColors.goldBright)),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load alerts',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertPostCard extends StatelessWidget {
  final AlertPost post;

  const _AlertPostCard({required this.post});

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.base),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width chart image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.base),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenImage(
                      imageBase64: post.imageBase64,
                      title: post.category,
                    ),
                  ),
                );
              },
              child: Image.memory(
                base64Decode(post.imageBase64),
                fit: BoxFit.fitWidth,
                width: double.infinity,
              ),
            ),
          ),

          // Text + timestamp
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.text,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.subtleGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(post.createdAt),
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
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageBase64;
  final String title;

  const _FullScreenImage({required this.imageBase64, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(base64Decode(imageBase64), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _VideoPopupDialog extends StatefulWidget {
  final VideoModel video;

  const _VideoPopupDialog({required this.video});

  @override
  State<_VideoPopupDialog> createState() => _VideoPopupDialogState();
}

class _VideoPopupDialogState extends State<_VideoPopupDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.metallicGold,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.metallicGold,
          handleColor: AppColors.goldBright,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white10,
        ),
      ),
      builder: (context, player) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pureBlack,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: AppColors.goldBright.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.video.title,
                              style: GoogleFonts.montserrat(
                                color: AppColors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.subtleGrey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      if (widget.video.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.video.description,
                          style: GoogleFonts.inter(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
