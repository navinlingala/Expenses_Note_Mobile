import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../home_navigation_screen.dart';
import 'models/auth_content_data.dart';
import 'widgets/auth_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().replaceAll(' ', '');
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorFillRequired)),
      );
      return;
    }

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorPasswordLength)),
      );
      return;
    }

    if (pass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AuthContentData.errorPasswordMismatch)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: name,
      email: email,
      phone: phone.isNotEmpty ? '+91$phone' : '+919010067464',
      password: pass,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      final userId = auth.currentUser!.id;
      await context.read<LoanProvider>().loadLoans(userId);
      if (!mounted) return;
      await context.read<TransactionProvider>().loadTransactions(userId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Registration failed')),
      );
    }
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

          // Scrollable Registration Form
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 6),

                  // Hero Emblem
                  const AuthHeaderEmblem(
                    icon: Icons.person_add_rounded,
                    accentColor: AppTheme.creditGreen,
                    size: 64,
                  ),

                  const SizedBox(height: 14),

                  // Title & Subtitle
                  Text(
                    AuthContentData.registerTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AuthContentData.registerSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Glassmorphic Form Card
                  AuthGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        AuthInputField(
                          controller: _nameCtrl,
                          label: AuthContentData.registerNameLabel,
                          hint: AuthContentData.registerNameHint,
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 12),

                        // Email Address
                        AuthInputField(
                          controller: _emailCtrl,
                          label: AuthContentData.registerEmailLabel,
                          hint: AuthContentData.registerEmailHint,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 12),

                        // WhatsApp / Phone
                        AuthInputField(
                          controller: _phoneCtrl,
                          label: AuthContentData.registerPhoneLabel,
                          hint: AuthContentData.registerPhoneHint,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 12),

                        // Password
                        AuthInputField(
                          controller: _passCtrl,
                          label: AuthContentData.registerPasswordLabel,
                          hint: AuthContentData.registerPasswordHint,
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePass,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              size: 19,
                            ),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Confirm Password
                        AuthInputField(
                          controller: _confirmPassCtrl,
                          label: AuthContentData.registerConfirmPasswordLabel,
                          hint: AuthContentData.registerConfirmPasswordHint,
                          icon: Icons.shield_outlined,
                          obscureText: _obscureConfirmPass,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              size: 19,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Register Primary Button
                        AuthPrimaryButton(
                          label: AuthContentData.registerButton,
                          onPressed: _handleRegister,
                          isLoading: _isLoading,
                          icon: Icons.arrow_forward_rounded,
                          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                          glowColor: const Color(0xFF10B981),
                        ),

                        const SizedBox(height: 18),

                        // Already have an account? Sign In
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text.rich(
                              TextSpan(
                                text: AuthContentData.alreadyHaveAccount,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                children: [
                                  TextSpan(
                                    text: AuthContentData.signInLink,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.creditGreen,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
