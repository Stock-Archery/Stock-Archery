import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/toast_util.dart';
import '../utils/design_system/design_system.dart';

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
  final _stateController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedOccupation;
  String? _selectedTradingExperience;
  String? _selectedGender;

  // Step and OTP flow variables
  int _currentStep = 1; // Step 1: Name & Phone verification, Step 2: Account details
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
    _stateController.dispose();
    _passwordController.dispose();
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
    if (cleanPhone.length != 10) return;

    setState(() {
      _sendOtpLoading = true;
      _otpError = null;
      _otpSent = false;
    });

    try {
      final otp = await ref.read(authProvider.notifier).sendOtp(cleanPhone);
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

    setState(() { _otpError = null; });

    final success = await ref.read(authProvider.notifier).verifyOtpOnly(cleanPhone, enteredOtp);

    if (success) {
      ToastUtil.showSuccess(context, "Phone Number Verified");
      setState(() {
        _currentStep = 2;
        _otpError = null;
      });
    } else {
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
          userState: _stateController.text.trim(),
          password: _passwordController.text.trim(),
          occupation: _selectedOccupation,
          tradingExperience: _selectedTradingExperience,
          gender: _selectedGender,
        );

    if (success && mounted) {
      ToastUtil.showSuccess(
        context,
        "Account Created!",
        description: "Welcome to Stock Archery.",
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.deepObsidian,
      appBar: AppBar(
        backgroundColor: AppColors.deepObsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
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
            style: AppTypography.headlineLg(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            "Step 1 of 2: Verify your phone number via SMS OTP code.",
            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 35),

          if (_otpError != null)
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
                      _otpError!,
                      style: AppTypography.bodyMd(color: AppColors.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                    onPressed: () => setState(() => _otpError = null),
                  ),
                ],
              ),
            ),

          // Full Name
          Text(
            "Full Name",
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyMd(color: AppColors.onSurface),
            decoration: _buildInputDecoration(
              "e.g. Prem Kumar",
              Icons.person_outline,
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Name is required' : null,
          ),

          const SizedBox(height: 20),

          // Phone Number
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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.deepObsidian,
                disabledBackgroundColor: AppColors.surfaceContainerLow,
                disabledForegroundColor: AppColors.subtleGrey,
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
                        color: AppColors.deepObsidian,
                        strokeWidth: 2.5,
                      ),
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

          const SizedBox(height: 30),

          // Verification Box Zone
          if (_otpSent) ...[
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
                        borderSide: const BorderSide(
                          color: AppColors.primary,
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
                          _verifyOtp();
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.deepObsidian,
                  disabledBackgroundColor: AppColors.surfaceContainerLow,
                  disabledForegroundColor: AppColors.subtleGrey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Verify OTP",
                  style: AppTypography.labelSm(color: AppColors.deepObsidian).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  children: [
                    TextSpan(
                      text: "Login",
                      style: AppTypography.bodyMd(color: AppColors.primary).copyWith(
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
            style: AppTypography.headlineLg(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            "Step 2 of 2: Set up your secure account password & profile data.",
            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 35),

          if (authState.errorMessage != null)
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
                      authState.errorMessage!,
                      style: AppTypography.bodyMd(color: AppColors.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                    onPressed: () =>
                        ref.read(authProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),

          // Email
          Text(
            "Email Address",
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTypography.bodyMd(color: AppColors.onSurface),
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

          // State
          Text(
            "State",
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _stateController,
            style: AppTypography.bodyMd(color: AppColors.onSurface),
            decoration: _buildInputDecoration(
              "e.g. Maharashtra",
              Icons.map_outlined,
            ),
            validator: (val) => val == null || val.trim().isEmpty
                ? 'State is required'
                : null,
          ),

          const SizedBox(height: 20),

          // Occupation
          Text(
            "Occupation",
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedOccupation,
              dropdownColor: AppColors.surfaceContainerLow,
              hint: Text(
                "Select your occupation",
                style: AppTypography.bodyMd(color: AppColors.subtleGrey),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant),
              borderRadius: BorderRadius.circular(12),
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.work_outline, size: 20, color: AppColors.onSurfaceVariant),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: InputBorder.none,
              ),
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'business', child: Text('Business')),
                DropdownMenuItem(value: 'self_employed', child: Text('Self Employed')),
                DropdownMenuItem(value: 'government_job', child: Text('Government Job')),
                DropdownMenuItem(value: 'private_sector_job', child: Text('Private Sector Job')),
              ],
              onChanged: (val) => setState(() => _selectedOccupation = val),
              validator: (val) => val == null ? 'Occupation is required' : null,
            ),
          ),

          const SizedBox(height: 20),

          // Trading Experience
          Text(
            "Trading Experience",
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedTradingExperience,
              dropdownColor: AppColors.surfaceContainerLow,
              hint: Text(
                "Select your experience level",
                style: AppTypography.bodyMd(color: AppColors.subtleGrey),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant),
              borderRadius: BorderRadius.circular(12),
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.show_chart, size: 20, color: AppColors.onSurfaceVariant),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: InputBorder.none,
              ),
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'experienced', child: Text('Experienced')),
              ],
              onChanged: (val) => setState(() => _selectedTradingExperience = val),
              validator: (val) => val == null ? 'Trading experience is required' : null,
            ),
          ),

          const SizedBox(height: 20),

          // Gender
          Text(
            "Gender",
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              dropdownColor: AppColors.surfaceContainerLow,
              hint: Text(
                "Select your gender",
                style: AppTypography.bodyMd(color: AppColors.subtleGrey),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant),
              borderRadius: BorderRadius.circular(12),
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.onSurfaceVariant),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: InputBorder.none,
              ),
              style: AppTypography.bodyMd(color: AppColors.onSurface),
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
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTypography.bodyMd(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: "Min 6 characters password",
              hintStyle: AppTypography.bodyMd(color: AppColors.subtleGrey),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
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
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.deepObsidian,
                disabledBackgroundColor: AppColors.surfaceContainerLow,
                disabledForegroundColor: AppColors.subtleGrey,
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
                        color: AppColors.deepObsidian,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Complete Profile",
                      style: AppTypography.labelSm(color: AppColors.deepObsidian).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
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
