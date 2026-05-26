import 'package:client/services/app_config.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      const VideoListView(),
      const StocksView(),
      const AiBotView(),
      const BrokersView(),
      const SubscriptionView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Archery',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
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
              // Finally, clear local session and Firebase session
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => ref.read(navigationProvider.notifier).state = index,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF6366F1), // Modern Indigo
          unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.play_circle_outline, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.play_circle_fill, size: 26),
              ),
              label: 'Strategy',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.trending_up_outlined, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.trending_up, size: 26),
              ),
              label: 'Stocks',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_outline, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble, size: 26),
              ),
              label: 'AI Bot',
            ),

            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.business_outlined, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.business, size: 26),
              ),
              label: 'Brokers',
            ),

            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.star_outline, size: 26),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.star, size: 26),
              ),
              label: 'Premium',
            ),
          ],
        ),
      ),
    );
  }
}
