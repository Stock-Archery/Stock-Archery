import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/toast_util.dart';
import 'signup_view.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 10) return oldValue;

    String formatted = '';
    if (text.length <= 5) {
      formatted = text;
    } else {
      formatted = '${text.substring(0, 5)} ${text.substring(5)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  // OTP login state
  bool _isOtpMode = false;
  bool _otpSent = false;
  bool _sendOtpLoading = false;
  String? _otpError;
  String? _expectedOtp;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _submitEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (success && mounted) {
      ToastUtil.showSuccess(context, "Welcome Back!", description: "Login successful.");
    }
  }

  void _sendOtp() async {
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length != 10) return;

    debugPrint('[log] [LoginView] _sendOtp triggered, phone: $cleanPhone');
    setState(() {
      _sendOtpLoading = true;
      _otpError = null;
      _otpSent = false;
    });

    try {
      final otp = await ref.read(authProvider.notifier).sendOtp(cleanPhone);
      debugPrint('[log] [LoginView] sendOtp returned: ${otp != null ? "OTP received" : "null"}');
      if (otp != null) {
        setState(() {
          _expectedOtp = otp;
          _otpSent = true;
          _sendOtpLoading = false;
        });
        if (mounted) _otpFocusNodes[0].requestFocus();
      } else {
        setState(() {
          _sendOtpLoading = false;
          _otpError = "Failed to send OTP. Please try again.";
        });
      }
    } catch (e) {
      debugPrint('[log] [LoginView] _sendOtp exception: $e');
      setState(() {
        _sendOtpLoading = false;
        _otpError = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  void _verifyAndLogin() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    debugPrint('[log] [LoginView] _verifyAndLogin, phone: $cleanPhone, otp: $enteredOtp');

    final success = await ref.read(authProvider.notifier).loginWithOtp(cleanPhone, enteredOtp);

    if (success && mounted) {
      ToastUtil.showSuccess(context, "Welcome Back!", description: "OTP login successful.");
    } else {
      setState(() {
        _otpError = ref.read(authProvider).errorMessage ?? "Invalid OTP. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isFirebaseConfigured = ref.read(authServiceProvider).isFirebaseAvailable;

    if (authState.isKickedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastUtil.showWarning(
          context,
          "Aapka account kisi aur device me login ho gaya hai!",
          description: "Multiple device login is restricted.",
        );
        ref.read(authProvider.notifier).clearKickedOut();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // Brand Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA500),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.gps_fixed_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ArrowAI",
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "Stock Archery's Smart Assistant",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  // Welcoming Text
                  Text(
                    "Welcome back",
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpMode
                        ? "Sign in with your phone number and OTP code."
                        : "Sign in to start technical analyses & market predictions.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Toggle: Email Login vs OTP Login
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isOtpMode = false;
                              _otpSent = false;
                              _otpError = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isOtpMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isOtpMode
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  "Email Login",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: !_isOtpMode ? Colors.black : Colors.grey[500],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isOtpMode = true;
                              _otpError = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isOtpMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isOtpMode
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  "OTP Login",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _isOtpMode ? Colors.black : Colors.grey[500],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (!isFirebaseConfigured)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Running in DEVELOPMENT Fallback Mode. Test instantly using any credentials!",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFC2410C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Error Banner
                  if (authState.errorMessage != null || _otpError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _otpError ?? authState.errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.red[800],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            onPressed: () {
                              setState(() => _otpError = null);
                              ref.read(authProvider.notifier).clearError();
                            },
                          )
                        ],
                      ),
                    ),

                  // ===== EMAIL LOGIN MODE =====
                  if (!_isOtpMode) ...[
                    Text(
                      "Email Address",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: _buildInputDecoration("e.g. name@domain.com", Icons.email_outlined),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Password",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: "Enter your secure password",
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.black45),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: Colors.black45,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password is required';
                        if (val.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _submitEmailLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                "Login Account",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],

                  // ===== OTP LOGIN MODE =====
                  if (_isOtpMode) ...[
                    Text(
                      "Phone Number",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: _buildInputDecoration("e.g. 98765 43210", Icons.phone_outlined),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Phone number is required';
                        if (val.replaceAll(RegExp(r'\D'), '').length != 10) return 'Enter exactly 10 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Send OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_phoneController.text.replaceAll(RegExp(r'\D'), '').length == 10 && !_sendOtpLoading)
                            ? _sendOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[200],
                          disabledForegroundColor: Colors.grey[400],
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _sendOtpLoading
                            ? const SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _otpSent ? "Resend OTP" : "Send OTP",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),

                    // OTP Input
                    if (_otpSent) ...[
                      const SizedBox(height: 30),
                      Text(
                        "Enter Verification Code",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 44,
                            height: 52,
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {});
                                if (value.isNotEmpty) {
                                  if (index < 5) {
                                    _otpFocusNodes[index + 1].requestFocus();
                                  } else {
                                    _otpFocusNodes[index].unfocus();
                                    // Auto-submit when all 6 digits entered
                                    _verifyAndLogin();
                                  }
                                } else {
                                  if (index > 0) {
                                    _otpFocusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_otpControllers.every((c) => c.text.isNotEmpty) && !authState.isLoading)
                              ? _verifyAndLogin
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[200],
                            disabledForegroundColor: Colors.grey[400],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 24, width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  "Verify & Login",
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 30),

                  // Switch to Signup
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupView()));
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      prefixIcon: Icon(prefixIcon, size: 20, color: Colors.black45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
    );
  }
}
