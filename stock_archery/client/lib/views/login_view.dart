import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/toast_util.dart';
import '../utils/design_system/design_system.dart';
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
  bool _isOtpMode = true;
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
          "Multiple Device Warning!",
          description: "Multiple device login is restricted.",
        );
        ref.read(authProvider.notifier).clearKickedOut();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Brand Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.gps_fixed_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "STOCK ARCHERY",
                            style: AppTypography.titleMd(color: AppColors.onSurface).copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            "Premium Trading Education & Insights",
                            style: AppTypography.labelSm(color: AppColors.subtleGrey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),

                  // Welcoming Text
                  Text(
                    "Welcome back",
                    style: AppTypography.headlineLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpMode
                        ? "Sign in with your phone number and OTP code."
                        : "Sign in to start technical analyses & market predictions.",
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),

                  const SizedBox(height: 30),

                  // Toggle: OTP Login vs Email Login
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isOtpMode = true;
                              _otpError = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isOtpMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "OTP Login",
                                  style: AppTypography.labelSm(
                                    color: _isOtpMode ? AppColors.deepObsidian : AppColors.subtleGrey,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                color: !_isOtpMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "Email Login",
                                  style: AppTypography.labelSm(
                                    color: !_isOtpMode ? AppColors.deepObsidian : AppColors.subtleGrey,
                                  ).copyWith(fontWeight: FontWeight.w700),
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
                        color: AppColors.surfaceContainerLow,
                        border: Border.all(color: AppColors.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Running in DEVELOPMENT Fallback Mode. Test instantly using any credentials!",
                              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
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
                        color: AppColors.errorContainer.withOpacity(0.2),
                        border: Border.all(color: AppColors.errorContainer),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _otpError ?? authState.errorMessage!,
                              style: AppTypography.bodyMd(color: AppColors.error),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.error),
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
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
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
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: "Enter your secure password",
                        hintStyle: AppTypography.bodyMd(color: AppColors.subtleGrey),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.onSurfaceVariant),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.deepObsidian,
                          disabledBackgroundColor: AppColors.surfaceContainerLow,
                          disabledForegroundColor: AppColors.subtleGrey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(color: AppColors.deepObsidian, strokeWidth: 2.5),
                              )
                            : Text(
                                "Login Account",
                                style: AppTypography.labelSm(color: AppColors.deepObsidian).copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // ===== OTP LOGIN MODE =====
                  if (_isOtpMode) ...[
                    Text(
                      "Phone Number",
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.deepObsidian,
                          disabledBackgroundColor: AppColors.surfaceContainerLow,
                          disabledForegroundColor: AppColors.subtleGrey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _sendOtpLoading
                            ? const SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(color: AppColors.deepObsidian, strokeWidth: 2.5),
                              )
                            : Text(
                                _otpSent ? "Resend OTP" : "Send OTP",
                                style: AppTypography.labelSm(color: AppColors.deepObsidian).copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),

                    // OTP Input
                    if (_otpSent) ...[
                      const SizedBox(height: 30),
                      Text(
                        "Enter Verification Code",
                        style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
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
                              style: AppTypography.headlineLg(color: AppColors.onSurface).copyWith(fontSize: 18),
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {});
                                if (value.isNotEmpty) {
                                  if (index < 5) {
                                    _otpFocusNodes[index + 1].requestFocus();
                                  } else {
                                    _otpFocusNodes[index].unfocus();
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
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.deepObsidian,
                            disabledBackgroundColor: AppColors.surfaceContainerLow,
                            disabledForegroundColor: AppColors.subtleGrey,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 24, width: 24,
                                  child: CircularProgressIndicator(color: AppColors.deepObsidian, strokeWidth: 2.5),
                                )
                              : Text(
                                  "Verify & Login",
                                  style: AppTypography.labelSm(color: AppColors.deepObsidian).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
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
                          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: AppTypography.bodyMd(color: AppColors.primary).copyWith(
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
      hintStyle: AppTypography.bodyMd(color: AppColors.subtleGrey),
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
