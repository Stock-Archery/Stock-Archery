import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  final String baseUrl;
  
  // Detect if Firebase Core is fully initialized with custom project configuration
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  AuthService({required this.baseUrl});

  /// Request a mock 4-digit SMS OTP for phone verification
  Future<String> sendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body['otp']?.toString() ?? '';
        }
        throw Exception(body['message'] ?? 'Failed to send OTP');
      } else {
        try {
          final errBody = jsonDecode(response.body);
          throw Exception(errBody['message'] ?? 'Failed to send OTP');
        } catch (_) {
          throw Exception('Failed to send OTP');
        }
      }
    } catch (e) {
      throw Exception('OTP service error: ${e.toString()}');
    }
  }

  // Keep a local in-memory session for the Mock environment
  UserModel? _mockUser;
  bool _isMockLoggedIn = false;

  UserModel? get mockUser => _mockUser;
  bool get isMockLoggedIn => _isMockLoggedIn;

  /// Listen to authenticating state changes
  Stream<User?> get authStateChanges {
    if (isFirebaseAvailable) {
      return FirebaseAuth.instance.authStateChanges();
    } else {
      // Empty mock stream
      return const Stream.empty();
    }
  }

  /// Signup a new user
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phoneNumber,
    required String location,
    required String password,
  }) async {
    if (isFirebaseAvailable) {
      // 1. Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception("Failed to register user in Firebase.");
      }

      // 2. Fetch JWT ID Token
      final idToken = await firebaseUser.getIdToken();

      // 3. Sync profile metadata with MongoDB backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'name': name,
          'phoneNumber': phoneNumber,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return UserModel.fromJson(body['user']);
      } else {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Backend profile synchronization failed.');
      }
    } else {
      // Fallback/Mock Mode: Sync directly with backend using a simulated UID
      print("⚠️ Firebase unavailable. Registering user in Mock / Development mode.");
      
      final mockUid = 'mock-uid-${email.split('@')[0]}';
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $mockUid',
        },
        body: jsonEncode({
          'name': name,
          'phoneNumber': phoneNumber,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _mockUser = UserModel.fromJson(body['user']);
        _isMockLoggedIn = true;
        return _mockUser!;
      } else {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Backend mock sync failed.');
      }
    }
  }

  /// Login an existing user
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (isFirebaseAvailable) {
      // 1. Sign in with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception("Failed to login user in Firebase.");
      }

      // 2. Fetch JWT ID Token
      final idToken = await firebaseUser.getIdToken();

      // 3. Sync session with MongoDB
      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({}), // Empty profile is fine for logins
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return UserModel.fromJson(body['user']);
      } else {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Backend profile sync failed.');
      }
    } else {
      // Mock Login Fallback: Check user existence using the backend
      print("⚠️ Firebase unavailable. Logging in via Mock / Development mode.");
      
      final mockUid = 'mock-uid-${email.split('@')[0]}';
      
      // We send a sync request with placeholder fields to satisfy requireAuth/registration logic
      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $mockUid',
        },
        body: jsonEncode({
          'name': email.split('@')[0].toUpperCase(),
          'phoneNumber': '0000000000',
          'location': 'Mock Location',
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _mockUser = UserModel.fromJson(body['user']);
        _isMockLoggedIn = true;
        return _mockUser!;
      } else {
        final errBody = jsonDecode(response.body);
        throw Exception(errBody['message'] ?? 'Backend mock sync failed.');
      }
    }
  }

  /// Sync user profile with MongoDB using an existing Firebase User ID Token
  Future<UserModel> syncProfile(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/sync'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({}), // Empty body since we are just syncing session
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return UserModel.fromJson(body['user']);
    } else {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['message'] ?? 'Backend profile sync failed.');
    }
  }

  /// Signout current session
  Future<void> logout() async {
    if (isFirebaseAvailable) {
      await FirebaseAuth.instance.signOut();
    } else {
      _mockUser = null;
      _isMockLoggedIn = false;
      print("👤 Mock session terminated successfully");
    }
  }
}
