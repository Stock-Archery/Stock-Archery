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
    final theme = Theme.of(context);

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
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.metallicGold, size: 28),
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 160,
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blueGrey),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ref.watch(authProvider).user?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+91 ${ref.watch(authProvider).user?.phoneNumber ?? ''}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ref.watch(authProvider).user?.isPremium == true
                          ? 'Premium Plan'
                          : 'Free Plan',
                      style: TextStyle(
                        color: ref.watch(authProvider).user?.isPremium == true
                            ? Colors.amber
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: navigate to Settings screen
              },
            ),
            ListTile(
              leading: Icon(Icons.support_agent),
              title: Text('Support'),
              onTap: () {
                Navigator.pop(context);
                // TODO: support callback
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
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
              },
            ),
          ],
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
}
