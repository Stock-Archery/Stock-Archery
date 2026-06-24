import 'package:client/views/auth_wrapper.dart';
import 'package:client/viewmodels/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

// Registers the FCM token with the backend, tying it to the physical device.
Future<void> _registerTokenWithBackend(String token) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user logged in, deferring token registration.');
      return;
    }

    final idToken = await user.getIdToken();
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown_device';
    String platform = 'unknown';

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceId = info.id;
      platform = 'android';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceId = info.identifierForVendor ?? 'unknown_ios';
      platform = 'ios';
    }

    // Assuming you have an API_URL in your .env
    final apiUrl = dotenv.env['DEV_BASE_URL'] ?? 'http://10.0.2.2:5000';

    final response = await http.post(
      Uri.parse('$apiUrl/user/device/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'token': token,
        'deviceId': deviceId,
        'platform': platform,
      }),
    );

    debugPrint('Token registration response: ${response.statusCode}');
  } catch (e) {
    debugPrint('Error registering token: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env", isOptional: true);
  } catch (error, stackTrace) {
    debugPrint('Warning: .env file could not be loaded: $error');
    debugPrint('$stackTrace');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Warning: Firebase could not be initialized: $error');
    debugPrint('$stackTrace');
  }

  // FCM Setup
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    final fcmToken = await messaging.getToken();
    debugPrint('FCM Device Token: $fcmToken');
    // Token registration on startup is deferred to AuthViewModel
    // to ensure the user is synced with the backend first.
  } catch (e) {
    debugPrint('Failed to get FCM token: $e');
  }

  // Listen to token refreshes
  messaging.onTokenRefresh
      .listen((fcmToken) {
        debugPrint('FCM Token Refreshed: $fcmToken');
        _registerTokenWithBackend(fcmToken);
      })
      .onError((err) {
        debugPrint('Token refresh error: $err');
      });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');
    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
    }
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Archery',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: settings.themeMode,
      home: const AuthWrapper(),
    );
  }
}
