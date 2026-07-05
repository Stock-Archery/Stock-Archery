import 'package:client/Features/payment/view_model/premium_provider.dart';
import 'package:client/services/app_config.dart';
import 'package:client/utils/design_system/design_system.dart';
import 'package:client/viewmodels/navigation_viewmodel.dart';
import 'package:client/views/ai_bot_view.dart';
import 'package:client/views/brokers_view.dart';
import 'package:client/views/stocks_view.dart';
import 'package:client/views/subscription_view.dart';
import 'package:client/views/video_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/viewmodels/auth_viewmodel.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);
    final user = ref.watch(authProvider).user;
    final isPremium = ref.watch(premiumProvider).isPremium;

    final List<Widget> screens = [
      const VideoListView(),
      const StocksView(),
      const AiBotView(),
      const BrokersView(),
      const SubscriptionView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      appBar: AppBar(
        backgroundColor: AppColors.deepObsidian,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Stock Archery',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.metallicGold,
              size: 28,
            ),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.subtleGrey.withValues(alpha: 0.12),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.deepObsidian,
        surfaceTintColor: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: [
              _ProfileHeader(
                name: user?.name,
                phoneNumber: user?.phoneNumber,
                isPremium: isPremium,
              ),
              const SizedBox(height: AppSpacing.lg),
              _DrawerActionTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: navigate to Settings screen
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _DrawerActionTile(
                icon: Icons.support_agent_outlined,
                title: 'Support',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: support callback
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _DrawerActionTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                isDestructive: true,
                onTap: () => _logout(context, ref),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceNav,
          border: Border(
            top: BorderSide(
              color: AppColors.subtleGrey.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => ref.read(navigationProvider.notifier).state = index,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.metallicGold,
          unselectedItemColor: AppColors.subtleGrey,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.play_circle_outline, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.play_circle_fill, size: 24),
              ),
              label: 'Strategy',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.trending_up_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.trending_up, size: 24),
              ),
              label: 'Stocks',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.smart_toy_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.smart_toy, size: 24),
              ),
              label: 'AI Bot',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.account_balance_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.account_balance, size: 24),
              ),
              label: 'Brokers',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.workspace_premium_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.workspace_premium, size: 24),
              ),
              label: 'Premium',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        final deviceInfo = DeviceInfoPlugin();
        String deviceId = 'unknown_device';
        if (Platform.isAndroid) {
          final info = await deviceInfo.androidInfo;
          deviceId = info.id;
        } else if (Platform.isIOS) {
          final info = await deviceInfo.iosInfo;
          deviceId = info.identifierForVendor ?? 'unknown_ios';
        }
        final apiUrl = AppConfig.baseUrl;
        await http.post(
          Uri.parse('$apiUrl/user/device/unregister'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'deviceId': deviceId}),
        );
      }
    } catch (e) {
      debugPrint('Token unregister error during logout: $e');
    }
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.pop(context);
  }
}

class _ProfileHeader extends StatelessWidget {
  final String? name;
  final String? phoneNumber;
  final bool isPremium;

  const _ProfileHeader({
    required this.name,
    required this.phoneNumber,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (name == null || name!.trim().isEmpty)
        ? 'Stock Archery User'
        : name!.trim();
    final displayPhone = (phoneNumber == null || phoneNumber!.trim().isEmpty)
        ? 'Phone not available'
        : '+91 ${phoneNumber!.trim()}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.goldBright.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldBright.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.goldBright.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayName.characters.first.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: AppColors.goldBright,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      displayPhone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.subtleGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isPremium
                  ? AppColors.goldBright.withValues(alpha: 0.12)
                  : AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: isPremium
                    ? AppColors.goldBright.withValues(alpha: 0.35)
                    : AppColors.subtleGrey.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPremium
                      ? Icons.workspace_premium_rounded
                      : Icons.account_circle_outlined,
                  size: 15,
                  color: isPremium
                      ? AppColors.goldBright
                      : AppColors.subtleGrey,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    isPremium ? 'PREMIUM PLAN' : 'FREE PLAN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isPremium
                          ? AppColors.goldBright
                          : AppColors.subtleGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.onSurface;
    final iconColor = isDestructive ? AppColors.error : AppColors.goldBright;

    return Material(
      color: AppColors.pureBlack,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: AppColors.subtleGrey.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 21),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtleGrey.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
