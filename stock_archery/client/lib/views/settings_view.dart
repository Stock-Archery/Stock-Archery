import 'package:client/utils/design_system/design_system.dart';
import 'package:client/viewmodels/auth_viewmodel.dart';
import 'package:client/viewmodels/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      appBar: AppBar(
        backgroundColor: AppColors.deepObsidian,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.subtleGrey.withValues(alpha: 0.12),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance Section ────────────────────────────────────
            _buildSectionHeader('APPEARANCE'),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _buildThemeTile(context, ref, settings),
                  _buildDivider(),
                  _buildLanguageTile(context, ref, settings),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Notifications Section ─────────────────────────────────
            _buildSectionHeader('NOTIFICATIONS'),
            const SizedBox(height: 12),
            _buildCard(
              child: _buildNotificationTile(ref),
            ),

            const SizedBox(height: 28),

            // ── Account Section ───────────────────────────────────────
            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                children: [
                  _buildProfileTile(user),
                  _buildDivider(),
                  _buildPremiumTile(user),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Support Section ───────────────────────────────────────
            _buildSectionHeader('SUPPORT'),
            const SizedBox(height: 12),
            _buildCard(
              child: _buildSupportTile(context),
            ),

            const SizedBox(height: 28),

            // ── About Section ─────────────────────────────────────────
            _buildSectionHeader('ABOUT'),
            const SizedBox(height: 12),
            _buildCard(
              child: _buildVersionTile(),
            ),

            const SizedBox(height: 28),

            // ── Logout ────────────────────────────────────────────────
            _buildLogoutButton(context, ref),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.metallicGold,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Card Wrapper ──────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.subtleGrey.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.subtleGrey.withValues(alpha: 0.08),
    );
  }

  // ── Theme Tile ────────────────────────────────────────────────────────────

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldBright.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dark_mode_outlined, color: AppColors.goldBright, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _themeModeLabel(settings.themeMode),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.subtleGrey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showThemeBottomSheet(context, ref, settings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _themeModeShortLabel(settings.themeMode),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.unfold_more, color: AppColors.subtleGrey, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'Follow system';
    }
  }

  String _themeModeShortLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.subtleGrey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Theme',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              context: context,
              ref: ref,
              title: 'Light',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
              currentMode: settings.themeMode,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              title: 'Dark',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
              currentMode: settings.themeMode,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              title: 'System Default',
              icon: Icons.phone_android_rounded,
              mode: ThemeMode.system,
              currentMode: settings.themeMode,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.goldBright : AppColors.subtleGrey,
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.goldBright : AppColors.onSurface,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.goldBright, size: 22)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        ref.read(settingsProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  // ── Language Tile ─────────────────────────────────────────────────────────

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldBright.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language_rounded, color: AppColors.goldBright, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  settings.language == AppLanguage.english ? 'English' : 'Hindi',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.subtleGrey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showLanguageBottomSheet(context, ref, settings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.language == AppLanguage.english ? 'EN' : 'HI',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.unfold_more, color: AppColors.subtleGrey, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.subtleGrey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Language',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              context: context,
              ref: ref,
              title: 'English',
              lang: AppLanguage.english,
              currentLang: settings.language,
            ),
            _buildLanguageOption(
              context: context,
              ref: ref,
              title: 'Hindi',
              lang: AppLanguage.hindi,
              currentLang: settings.language,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required AppLanguage lang,
    required AppLanguage currentLang,
  }) {
    final isSelected = lang == currentLang;
    return ListTile(
      leading: Icon(
        lang == AppLanguage.english ? Icons.translate : Icons.g_translate_rounded,
        color: isSelected ? AppColors.goldBright : AppColors.subtleGrey,
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.goldBright : AppColors.onSurface,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.goldBright, size: 22)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        ref.read(settingsProvider.notifier).setLanguage(lang);
        Navigator.pop(context);
      },
    );
  }

  // ── Notification Tile ─────────────────────────────────────────────────────

  Widget _buildNotificationTile(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldBright.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.goldBright, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Receive alerts for recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.subtleGrey,
                  ),
                ),
              ],
            ),
          ),
          // Placeholder toggle — not wired to backend yet
          Switch(
            value: true,
            onChanged: (val) {
              // TODO: wire to FCM topic subscribe/unsubscribe
            },
            activeColor: AppColors.goldBright,
            activeTrackColor: AppColors.goldBright.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.subtleGrey,
            inactiveTrackColor: AppColors.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }

  // ── Profile Tile ──────────────────────────────────────────────────────────

  Widget _buildProfileTile(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.goldBright.withValues(alpha: 0.15),
            child: Text(
              (user?.name ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.goldBright,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.subtleGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.subtleGrey, size: 20),
        ],
      ),
    );
  }

  // ── Premium Tile ──────────────────────────────────────────────────────────

  Widget _buildPremiumTile(dynamic user) {
    final isPremium = user?.isPremium ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPremium
                  ? AppColors.goldBright.withValues(alpha: 0.15)
                  : AppColors.subtleGrey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: isPremium ? AppColors.goldBright : AppColors.subtleGrey,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium Active' : 'Free Plan',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPremium ? AppColors.goldBright : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium
                      ? (user?.premiumExpiresAt != null
                          ? 'Expires ${user!.premiumExpiresAt!.toLocal().toString().split(' ')[0]}'
                          : 'Active')
                      : 'Upgrade for premium features',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.subtleGrey,
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.goldBright,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'UPGRADE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepObsidian,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Support Tile ──────────────────────────────────────────────────────────

  Widget _buildSupportTile(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse('https://stockarchery-privacy.netlify.app/');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldBright.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.goldBright, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help & Support',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Privacy policy & support',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.subtleGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AppColors.subtleGrey, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Version Tile ──────────────────────────────────────────────────────────

  Widget _buildVersionTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldBright.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.goldBright, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Version',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock Archery v1.0.0+3',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.subtleGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout Button ─────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                side: BorderSide(color: AppColors.subtleGrey.withValues(alpha: 0.12)),
              ),
              title: Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.inter(
                  color: AppColors.subtleGrey,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: AppColors.subtleGrey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldLogout == true && context.mounted) {
            await ref.read(authProvider.notifier).logout();
          }
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
        label: Text(
          'Logout',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
        ),
      ),
    );
  }
}
