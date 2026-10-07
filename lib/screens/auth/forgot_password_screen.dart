import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'models/auth_content_data.dart';
import 'widgets/auth_components.dart';

// =========================================================================
// 1. FORGOT PASSWORD SCREEN (Step 1: Enter email/phone)
// =========================================================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorFillRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthAmbientBackground(
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Text(
                  AuthContentData.appName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 42),
              ],
            ),
          ),

          // Main Form
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Hero Emblem
                  const AuthHeaderEmblem(
                    icon: Icons.key_rounded,
                    accentColor: AppTheme.secondary,
                    size: 68,
                  ),

                  const SizedBox(height: 18),

                  // Title & Subtitle
                  Text(
                    AuthContentData.forgotTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AuthContentData.forgotSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Glassmorphic Card
                  AuthGlassCard(
                    child: Column(
                      children: [
                        AuthInputField(
                          controller: _emailCtrl,
                          label: AuthContentData.forgotEmailLabel,
                          hint: AuthContentData.forgotEmailHint,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        AuthPrimaryButton(
                          label: AuthContentData.forgotSubmitButton,
                          onPressed: _handleSendCode,
                          isLoading: _isLoading,
                          icon: Icons.arrow_forward_rounded,
                          gradientColors: const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                          glowColor: const Color(0xFF0EA5E9),
                        ),

                        const SizedBox(height: 18),

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            AuthContentData.backToSignIn,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 2. OTP VERIFICATION SCREEN (Step 2: 6-digit code)
// =========================================================================
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Empty initial controllers waiting for user input

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    final code = _otpControllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorInvalidOtp)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AuthContentData.successOtpVerified),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: widget.email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthAmbientBackground(
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Text(
                  AuthContentData.appName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 42),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Hero Emblem
                  const AuthHeaderEmblem(
                    icon: Icons.verified_user_rounded,
                    accentColor: AppTheme.creditGreen,
                    size: 68,
                  ),

                  const SizedBox(height: 18),

                  // Title & Subtitle
                  Text(
                    AuthContentData.otpTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${AuthContentData.otpSubtitle} ${widget.email}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Glassmorphic Card with 6-digit OTP Inputs
                  AuthGlassCard(
                    child: Column(
                      children: [
                        // 6-digit Responsive Box Inputs
                        Row(
                          children: List.generate(6, (index) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: index == 0 || index == 5 ? 2 : 3),
                                child: _buildOtpBox(index, isDark),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 18),

                        // Demo security code notice pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF10B981).withAlpha(isDark ? 80 : 50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  AuthContentData.otpDemoNotice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Resend Countdown or Active Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_secondsRemaining > 0) ...[
                              Icon(Icons.timer_outlined,
                                  size: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${AuthContentData.otpResendCountdown} 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: _startTimer,
                                child: Text(
                                  AuthContentData.otpResendButton,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Verify Primary Button
                        AuthPrimaryButton(
                          label: AuthContentData.otpVerifyButton,
                          onPressed: _verifyOtp,
                          icon: Icons.arrow_forward_rounded,
                          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                          glowColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index, bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withAlpha(160) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _otpControllers[index].text.isNotEmpty
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: 1.5,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }
}

// =========================================================================
// 3. RESET PASSWORD SCREEN (Step 3: New password)
// =========================================================================
class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorFillRequired)),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorPasswordLength)),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorPasswordMismatch)),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AuthContentData.successPasswordReset),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthAmbientBackground(
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Text(
                  AuthContentData.appName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 42),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Hero Emblem
                  const AuthHeaderEmblem(
                    icon: Icons.lock_reset_rounded,
                    accentColor: AppTheme.primary,
                    size: 68,
                  ),

                  const SizedBox(height: 18),

                  // Title & Subtitle
                  Text(
                    AuthContentData.resetTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AuthContentData.resetSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Glassmorphic Card
                  AuthGlassCard(
                    child: Column(
                      children: [
                        AuthInputField(
                          controller: _newPassCtrl,
                          label: AuthContentData.resetNewPasswordLabel,
                          hint: AuthContentData.resetNewPasswordHint,
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureNew,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              size: 19,
                            ),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),

                        const SizedBox(height: 14),

                        AuthInputField(
                          controller: _confirmPassCtrl,
                          label: AuthContentData.resetConfirmPasswordLabel,
                          hint: AuthContentData.resetConfirmPasswordHint,
                          icon: Icons.shield_outlined,
                          obscureText: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              size: 19,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),

                        const SizedBox(height: 22),

                        AuthPrimaryButton(
                          label: AuthContentData.resetSubmitButton,
                          onPressed: _handleResetPassword,
                          isLoading: _isLoading,
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
