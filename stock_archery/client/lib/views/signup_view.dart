import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/toast_util.dart';
import '../services/app_config.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep only numeric characters
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 10) {
      return oldValue; // Cap at 10 digits
    }

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

class SignupView extends ConsumerStatefulWidget {
  const SignupView({super.key});

  @override
  ConsumerState<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends ConsumerState<SignupView> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _occupationDetailController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedOccupation;
  String? _selectedGender;

  // Step and OTP flow variables
  int _currentStep =
      1; // Step 1: Name & Phone verification, Step 2: Account details
  bool _otpSent = false;
  String? _expectedOtp;
  bool _sendOtpLoading = false;
  String? _otpError;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _occupationDetailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _sendOtp() async {
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    debugPrint('[log] [SignupView] _sendOtp triggered, phone: $cleanPhone');
    debugPrint('[log] [SignupView] baseUrl: ${AppConfig.baseUrl}');
    debugPrint('[log] [SignupView] environment: ${AppConfig.environment}');
    if (cleanPhone.length != 10) {
      debugPrint('[log] [SignupView] Invalid phone length: ${cleanPhone.length}');
      return;
    }

    setState(() {
      _sendOtpLoading = true;
      _otpError = null;
      _otpSent = false;
    });

    try {
      debugPrint('[log] [SignupView] Calling authViewModel.sendOtp...');
      final otp = await ref.read(authProvider.notifier).sendOtp(cleanPhone);
      debugPrint('[log] [SignupView] sendOtp returned: ${otp != null ? "OTP received" : "null"}');
      if (otp != null) {
        setState(() {
          _expectedOtp = otp;
          _otpSent = true;
          _sendOtpLoading = false;
        });

        // Focus the first OTP box
        if (mounted) {
          _otpFocusNodes[0].requestFocus();
        }
      } else {
        setState(() {
          _sendOtpLoading = false;
          _otpError = "Failed to send OTP. Please try again.";
        });
      }
    } catch (e) {
      debugPrint('[log] [SignupView] _sendOtp exception: $e');
      setState(() {
        _sendOtpLoading = false;
        _otpError = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  bool _isVerifyEnabled() {
    return _otpControllers.every((c) => c.text.isNotEmpty);
  }

  void _verifyOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    debugPrint('[log] [SignupView] _verifyOtp called, phone: $cleanPhone, otp: $enteredOtp');

    setState(() { _otpError = null; });

    final success = await ref.read(authProvider.notifier).verifyOtpOnly(cleanPhone, enteredOtp);

    if (success) {
      debugPrint('[log] [SignupView] Server-side OTP verified');
      setState(() {
        _currentStep = 2;
        _otpError = null;
      });
      ToastUtil.showSuccess(context, "Phone Number Verified");
    } else {
      debugPrint('[log] [SignupView] Server-side OTP verification failed');
      setState(() {
        _otpError = "Invalid OTP. Please try again.";
      });
      ToastUtil.showError(context, "Wrong OTP!");
    }
  }

  void _submitProfile() async {
    if (!_formKey2.currentState!.validate()) return;

    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    final success = await ref
        .read(authProvider.notifier)
        .signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: cleanPhone,
          location: _locationController.text.trim(),
          password: _passwordController.text.trim(),
          occupation: _selectedOccupation,
          occupationDetail: _selectedOccupation == 'others'
              ? _occupationDetailController.text.trim()
              : null,
          gender: _selectedGender,
        );

    if (success && mounted) {
      ToastUtil.showSuccess(
        context,
        "Account Created!",
        description: "Welcome to ArrowAI.",
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() {
                _currentStep = 1;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 10.0,
            ),
            child: _currentStep == 1 ? _buildStep1() : _buildStep2(authState),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final isSendOtpEnabled =
        phoneDigits.length == 10 && _nameController.text.trim().isNotEmpty;

    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Verify Phone",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Step 1 of 2: Let's verify your identity via SMS code.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 35),

          if (_otpError != null)
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
                      _otpError!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: () => setState(() => _otpError = null),
                  ),
                ],
              ),
            ),

          // Full Name
          Text(
            "Full Name",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _buildInputDecoration(
              "e.g. John Doe",
              Icons.person_outline,
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Name is required' : null,
          ),

          const SizedBox(height: 20),

          // Phone Number
          Text(
            "Phone Number",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _buildInputDecoration(
              "e.g. 98765 43210",
              Icons.phone_outlined,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty)
                return 'Phone number is required';
              if (val.replaceAll(RegExp(r'\D'), '').length != 10)
                return 'Enter exactly 10 digits';
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Send OTP Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isSendOtpEnabled && !_sendOtpLoading ? _sendOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _sendOtpLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Send OTP",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 30),

          // Verification Box Zone
          if (_otpSent) ...[
            Text(
              "Enter Verification Code",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
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
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Trigger refresh of Verify Button state
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else {
                          _otpFocusNodes[index].unfocus();
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
                onPressed: _isVerifyEnabled() ? _verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[400],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Verify OTP",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Back to Login Link
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: "Login",
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep2(AuthState authState) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Complete Profile",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Step 2 of 2: Create secure credentials to access ArrowAI.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 35),

          if (authState.errorMessage != null)
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
                      authState.errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: () =>
                        ref.read(authProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),

          // Email
          Text(
            "Email Address",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _buildInputDecoration(
              "e.g. name@domain.com",
              Icons.email_outlined,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Location
          Text(
            "Location",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _buildInputDecoration(
              "e.g. Mumbai, India",
              Icons.location_on_outlined,
            ),
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Location is required'
                : null,
          ),

          const SizedBox(height: 20),

          // Occupation
          Text(
            "Occupation",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedOccupation,
              hint: Text(
                "Select your occupation",
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.work_outline, size: 20, color: Colors.black45),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'businessman', child: Text('Businessman')),
                DropdownMenuItem(value: 'others', child: Text('Others')),
              ],
              onChanged: (val) => setState(() => _selectedOccupation = val),
              validator: (val) => val == null ? 'Occupation is required' : null,
            ),
          ),

          // Occupation detail (shown only when "others" is selected)
          if (_selectedOccupation == 'others') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _occupationDetailController,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: _buildInputDecoration(
                "Specify your occupation",
                Icons.edit_outlined,
              ),
              validator: (val) {
                if (_selectedOccupation == 'others' && (val == null || val.trim().isEmpty)) {
                  return 'Please specify your occupation';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 20),

          // Gender
          Text(
            "Gender",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              hint: Text(
                "Select your gender",
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, size: 20, color: Colors.black45),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'others', child: Text('Others')),
              ],
              onChanged: (val) => setState(() => _selectedGender = val),
              validator: (val) => val == null ? 'Gender is required' : null,
            ),
          ),

          const SizedBox(height: 20),

          // Password
          Text(
            "Password",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: "Min 6 characters password",
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 20,
                color: Colors.black45,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.black45,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1.5,
                ),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Password is required';
              if (val.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
          ),

          const SizedBox(height: 40),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Complete Profile",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
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
