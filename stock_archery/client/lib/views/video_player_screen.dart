import 'package:client/models/video_model.dart';
import 'package:client/utils/design_system/design_system.dart';
import 'package:flutter/material.dart';
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
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
            child: Icon(icon, color: AppColors.goldBright, size: 24),
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
                              'Module 3 • Advanced Trading',
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
                            'PREMIUM CONTENT',
                            style: GoogleFonts.inter(
                              color: AppColors.premiumAmber,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

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
                                    'Stock Archery Academy',
                                    style: GoogleFonts.montserrat(
                                      color: AppColors.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '120K Students • 4.9 Rating',
                                    style: GoogleFonts.inter(
                                      color: AppColors.subtleGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
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
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              'Save',
                              () {
                                setState(() {
                                  isSaved = !isSaved;
                                });
                              },
                            ),
                            _buildActionButton(
                              Icons.thumb_up_alt_outlined,
                              'Like',
                              () {},
                            ),
                            _buildActionButton(
                              Icons.download_rounded,
                              'Download',
                              () {},
                            ),
                            _buildActionButton(
                              Icons.share_rounded,
                              'Share',
                              () {},
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
                        Container(
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
                                      widget.video.thumbnail,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: AppColors.metallicGold.withValues(
                                        alpha: 0.20,
                                      ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      'Price Action & Breakout Analysis',
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
                        const SizedBox(height: 40),
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
