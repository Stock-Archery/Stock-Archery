import 'package:client/models/video_model.dart';
import 'package:client/utils/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool isSaved = false;
  bool isLiked = false;
  bool isFollowing = false;
  bool isDownloading = false;
  bool isDownloaded = false;
  double downloadProgress = 0.0;

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

  String get _derivedModule {
    final title = widget.video.title.toLowerCase();
    if (title.contains('part 1')) return 'Module 1 • Option Fundamentals';
    if (title.contains('part 2')) return 'Module 2 • Strategy & Execution';
    if (title.contains('part 3')) return 'Module 3 • Advanced Risk Management';
    if (title.contains('sob')) {
      if (title.contains('free')) return 'SOB Alerts • Promo Guide';
      return 'SOB Alerts • Platform Tutorial';
    }
    if (title.contains('xaud')) {
      if (title.contains('free')) return 'XAUD Alerts • Promo Guide';
      return 'XAUD Alerts • Platform Tutorial';
    }
    if (title.contains('crypto')) {
      if (title.contains('free')) return 'Crypto Alerts • Promo Guide';
      return 'Crypto Alerts • Platform Tutorial';
    }
    return 'Stock Archery Masterclass';
  }

  String get _derivedBadge {
    final title = widget.video.title.toLowerCase();
    if (title.contains('free') || title.contains('part')) {
      return 'FREE ACCESS';
    }
    return 'PREMIUM CONTENT';
  }

  String get _derivedCreatorName {
    final title = widget.video.title.toLowerCase();
    if (title.contains('sob') ||
        title.contains('xaud') ||
        title.contains('crypto')) {
      return 'Stock Archery Support';
    }
    return 'Stock Archery Academy';
  }

  String get _derivedCreatorInfo {
    final title = widget.video.title.toLowerCase();
    if (title.contains('sob') ||
        title.contains('xaud') ||
        title.contains('crypto')) {
      return 'Official Guide • Support';
    }
    return '120K Students • 4.9 Rating';
  }

  VideoModel? _getNextVideo() {
    final list = [
      VideoModel(
        title: "Stock Option Buying strategy Part 1",
        videoId: "BKoWmDwlfnQ",
        thumbnail: "https://img.youtube.com/vi/BKoWmDwlfnQ/0.jpg",
        description:
            "Learn the fundamentals of option buying with real market examples.",
      ),
      VideoModel(
        title: "Stock Option Buying strategy Part 2",
        videoId: "MnopZVm7baM",
        thumbnail: "https://img.youtube.com/vi/MnopZVm7baM/0.jpg",
        description:
            "Build advanced strategies for trading stock options in volatile markets.",
      ),
      VideoModel(
        title: "Stock Option Buying strategy Part 3",
        videoId: "bDLYO5D7RoE",
        thumbnail: "https://img.youtube.com/vi/bDLYO5D7RoE/0.jpg",
        description:
            "Master risk management, strike selection, and execution timing.",
      ),
    ];

    final index = list.indexWhere((v) => v.videoId == widget.video.videoId);
    if (index != -1 && index < list.length - 1) {
      return list[index + 1];
    }
    return null;
  }

  void _toggleSave() {
    setState(() {
      isSaved = !isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.pureBlack,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLiked ? 'Added to liked videos' : 'Removed from liked videos',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.pureBlack,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleFollow() {
    setState(() {
      isFollowing = !isFollowing;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFollowing
              ? 'Following $_derivedCreatorName'
              : 'Unfollowed $_derivedCreatorName',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.pureBlack,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareVideo() {
    final videoUrl = 'https://www.youtube.com/watch?v=${widget.video.videoId}';
    Clipboard.setData(ClipboardData(text: videoUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Video link copied to clipboard!',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.pureBlack,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startDownloadSimulation() async {
    if (isDownloading) return;
    if (isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video is already saved offline.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.pureBlack,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Starting download...',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.pureBlack,
        duration: const Duration(seconds: 1),
      ),
    );

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        downloadProgress = i / 10.0;
      });
    }

    if (!mounted) return;
    setState(() {
      isDownloading = false;
      isDownloaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Video downloaded successfully for offline viewing!',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? customIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.pureBlack,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.goldBright.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child:
                customIcon ??
                Icon(icon, color: iconColor ?? AppColors.goldBright, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.subtleGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
        final nextVideo = _getNextVideo();
        return Scaffold(
          backgroundColor: AppColors.deepObsidian,
          body: SafeArea(
            child: Column(
              children: [
                /// TOP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.pureBlack,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.subtleGrey.withValues(
                                alpha: 0.12,
                              ),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.onSurface,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                color: AppColors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _derivedModule,
                              style: GoogleFonts.inter(
                                color: AppColors.subtleGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.pureBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.subtleGrey.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.cast_rounded,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                /// VIDEO PLAYER
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: player,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// PREMIUM BADGE
                        if (_derivedBadge.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.metallicGold.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.metallicGold.withValues(
                                  alpha: 0.40,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _derivedBadge,
                              style: GoogleFonts.inter(
                                color: AppColors.premiumAmber,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        /// TITLE
                        Text(
                          widget.video.title,
                          style: GoogleFonts.montserrat(
                            color: AppColors.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// CREATOR INFO
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.goldBright.withValues(
                                alpha: 0.12,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.goldBright,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _derivedCreatorName,
                                    style: GoogleFonts.montserrat(
                                      color: AppColors.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _derivedCreatorInfo,
                                    style: GoogleFonts.inter(
                                      color: AppColors.subtleGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isFollowing
                                ? OutlinedButton(
                                    onPressed: _toggleFollow,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.subtleGrey,
                                      side: BorderSide(
                                        color: AppColors.subtleGrey.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Following',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.metallicGold,
                                      foregroundColor: const Color(0xFF0B0E11),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Follow',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        /// ACTION BUTTONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              iconColor: isSaved
                                  ? AppColors.goldBright
                                  : AppColors.goldBright.withValues(alpha: 0.7),
                              label: isSaved ? 'Saved' : 'Save',
                              onTap: _toggleSave,
                            ),
                            _buildActionButton(
                              icon: isLiked
                                  ? Icons.thumb_up_alt
                                  : Icons.thumb_up_alt_outlined,
                              iconColor: isLiked
                                  ? AppColors.goldBright
                                  : AppColors.goldBright.withValues(alpha: 0.7),
                              label: isLiked ? 'Liked' : 'Like',
                              onTap: _toggleLike,
                            ),
                            _buildActionButton(
                              icon: Icons.download_rounded,
                              label: isDownloading
                                  ? '${(downloadProgress * 100).toInt()}%'
                                  : (isDownloaded ? 'Saved' : 'Download'),
                              onTap: _startDownloadSimulation,
                              customIcon: isDownloading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        value: downloadProgress,
                                        strokeWidth: 2.5,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.goldBright,
                                            ),
                                      ),
                                    )
                                  : (isDownloaded
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.green,
                                            size: 24,
                                          )
                                        : null),
                            ),
                            _buildActionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              onTap: _shareVideo,
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// DESCRIPTION CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.pureBlack,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.subtleGrey.withValues(
                                alpha: 0.12,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About this Lecture',
                                style: GoogleFonts.montserrat(
                                  color: AppColors.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.video.description,
                                style: GoogleFonts.inter(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 14,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// NEXT LECTURE CARD
                        if (nextVideo != null) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VideoPlayerScreen(video: nextVideo),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.pureBlack,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.goldBright.withValues(
                                    alpha: 0.16,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.network(
                                          nextVideo.thumbnail,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          color: AppColors.metallicGold
                                              .withValues(alpha: 0.20),
                                          border: Border.all(
                                            color: AppColors.metallicGold
                                                .withValues(alpha: 0.50),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: AppColors.goldBright,
                                          size: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Next Lecture',
                                          style: GoogleFonts.inter(
                                            color: AppColors.subtleGrey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          nextVideo.title,
                                          style: GoogleFonts.montserrat(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.goldBright,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
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
