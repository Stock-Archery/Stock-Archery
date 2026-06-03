import 'package:client/views/video_player_screen.dart';
import 'package:client/viewmodels/video_viewmodel.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:client/utils/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoListView extends ConsumerStatefulWidget {
  const VideoListView({super.key});

  @override
  ConsumerState<VideoListView> createState() => _VideoListViewState();
}

class _VideoListViewState extends ConsumerState<VideoListView> {
  // int _selectedLevel = 2; // 0=Beginner 1=Intermediate 2=Advanced
  // final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(videoProvider);
    final user = ref.watch(authProvider).user;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ─────────────────────────────────────────────────
          // SliverAppBar(
          //   expandedHeight: 0,
          //   floating: true,
          //   snap: true,
          //   pinned: false,
          //   backgroundColor: AppColors.deepObsidian.withOpacity(0.92),
          //   elevation: 0,
          //   automaticallyImplyLeading: false,
          //   flexibleSpace: null,
          // ),

          // ── Hero Header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strategy Videos',
                    style: GoogleFonts.montserrat(
                      color: AppColors.metallicGold,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Master the markets with our elite curated curriculum.',
                    style: GoogleFonts.inter(
                      color: AppColors.subtleGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Free Video Cards ───────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = videos[index];
              return _VideoCard(
                video: video,
                index: index,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(video: video),
                    ),
                  );
                },
              );
            }, childCount: videos.length),
          ),

          // ── Premium Locked Card ───────────────────────────────────────────
          SliverToBoxAdapter(child: _PremiumLockedCard(isPremium: isPremium)),

          // ── Browse by Level ───────────────────────────────────────────────
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
          //     child: Text(
          //       'Browse by Level',
          //       style: GoogleFonts.montserrat(
          //         color: AppColors.onSurface,
          //         fontSize: 20,
          //         fontWeight: FontWeight.w600,
          //         letterSpacing: -0.3,
          //       ),
          //     ),
          //   ),
          // ),

          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 20),
          //     child: Row(
          //       children: List.generate(_levels.length, (i) {
          //         final selected = _selectedLevel == i;
          //         return Padding(
          //           padding: const EdgeInsets.only(right: 10),
          //           child: GestureDetector(
          //             onTap: () => setState(() => _selectedLevel = i),
          //             child: AnimatedContainer(
          //               duration: const Duration(milliseconds: 200),
          //               padding: const EdgeInsets.symmetric(
          //                 horizontal: 18,
          //                 vertical: 10,
          //               ),
          //               decoration: BoxDecoration(
          //                 color: selected ? AppColors.metallicGold : AppColors.surfaceContainer,
          //                 borderRadius: BorderRadius.circular(24),
          //                 border: Border.all(
          //                   color: selected
          //                       ? AppColors.metallicGold
          //                       : AppColors.outlineVariant.withOpacity(0.5),
          //                   width: 1,
          //                 ),
          //               ),
          //               child: Text(
          //                 _levels[i],
          //                 style: GoogleFonts.inter(
          //                   color: selected
          //                       ? const Color(0xFF0B0E11)
          //                       : AppColors.subtleGrey,
          //                   fontSize: 13,
          //                   fontWeight: selected
          //                       ? FontWeight.w700
          //                       : FontWeight.w500,
          //                 ),
          //               ),
          //             ),
          //           ),
          //         );
          //       }),
          //     ),
          //   ),
          // ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Video Card ─────────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final dynamic video;
  final int index;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.index,
    required this.onTap,
  });

  String _formatDuration(int index) {
    // Mock durations mirroring the reference design
    final durations = ['12:04', '15:20', '22:10'];
    return index < durations.length ? durations[index] : '10:00';
  }

  String _formatMeta(int index) {
    final metas = [
      'Featured Video • 12 mins • 5k views',
      'Featured Video • 15 mins • 3.2k views',
      'Featured Video • 22 mins • 1.8k views',
    ];
    return index < metas.length ? metas[index] : 'Featured Video';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.pureBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.subtleGrey.withOpacity(0.12), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    video.thumbnail,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFF1A1A1A),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: AppColors.subtleGrey,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  // Dark gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Glassmorphic play button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.metallicGold.withOpacity(0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.metallicGold.withOpacity(0.70),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.goldBright,
                      size: 36,
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(index),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Metadata ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                video.title,
                style: GoogleFonts.montserrat(
                  color: AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 13,
                    color: AppColors.subtleGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatMeta(index),
                    style: GoogleFonts.inter(
                      color: AppColors.subtleGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // ── Watch Now CTA ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.metallicGold,
                  side: const BorderSide(color: AppColors.metallicGold, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'WATCH NOW',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.metallicGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.metallicGold),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Premium Locked Card ────────────────────────────────────────────────────
class _PremiumLockedCard extends StatelessWidget {
  final bool isPremium;
  const _PremiumLockedCard({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.metallicGold.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.metallicGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.metallicGold.withOpacity(0.40), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 13,
                    color: AppColors.premiumAmber,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'PREMIUM',
                    style: GoogleFonts.inter(
                      color: AppColors.premiumAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lock icon + upgrade text
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.metallicGold.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.metallicGold.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.premiumAmber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upgrade to Premium to Unlock',
                    style: GoogleFonts.inter(
                      color: AppColors.premiumAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Video title + meta
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Advanced Gamma Squeeze Indicators',
              style: GoogleFonts.montserrat(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 13,
                  color: AppColors.subtleGrey,
                ),
                const SizedBox(width: 5),
                Text(
                  'Premium Exclusive • 45 mins',
                  style: GoogleFonts.inter(color: AppColors.subtleGrey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Upgrade Now CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: ElevatedButton(
              onPressed: isPremium ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.metallicGold,
                foregroundColor: const Color(0xFF0B0E11),
                disabledBackgroundColor: AppColors.metallicGold.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                minimumSize: const Size(double.infinity, 48),
                elevation: 0,
              ),
              child: Text(
                isPremium ? 'ALREADY PREMIUM' : 'UPGRADE NOW',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF0B0E11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
