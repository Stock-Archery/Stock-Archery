import 'dart:convert';
import 'package:client/models/alert_post.dart';
import 'package:client/utils/design_system/design_system.dart';
import 'package:client/viewmodels/alerts_provider.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AlertsView extends ConsumerWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final user = ref.watch(authProvider).user;

    bool isCategoryLocked(String category) {
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
                ? _buildLockedState(selectedCategory)
                : _AlertFeed(category: selectedCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState(String category) {
    return Center(
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
          ],
        ),
      ),
    );
  }
}

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
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.goldBright),
      ),
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
          child: Image.memory(
            base64Decode(imageBase64),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
