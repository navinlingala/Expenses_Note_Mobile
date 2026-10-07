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
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Ultra-Premium Next-Generation Authentication Screen for Money Reminder App
/// Features luxury glassmorphism, animated entrance choreography, ambient glow orbs,
/// instant demo persona auto-fill, and 100% responsive constraint scaling.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _prefillDemoCredentials(String email, String password, String role) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = password;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Demo credentials loaded: $role',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.primary, width: 1),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthContentData.errorFillRequired, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.debitRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.login(email, pass);
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
        SnackBar(
          content: Text(auth.errorMessage ?? AuthContentData.errorInvalidCredentials, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.debitRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _handleExploreApp() {
    context.read<AuthProvider>().continueAsGuest();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthAmbientBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Utility Bar with Guaranteed Responsive Fit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Security Shield Capsule
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B).withAlpha(180) : Colors.white.withAlpha(200),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.creditGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x8010B981),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '256-Bit Vault',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Explore Guest Pill Button
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: InkWell(
                            onTap: _handleExploreApp,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    AuthContentData.exploreGuest,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Hero 3D Emblem
                    const AuthHeaderEmblem(
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: AppTheme.primary,
                      size: 62,
                    ),

                    const SizedBox(height: 14),

                    // Welcome Back Heading
                    Text(
                      AuthContentData.loginWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AuthContentData.loginWelcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Quick Demo Persona Switcher Bar
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildDemoPill(
                          label: 'Demo User',
                          email: 'naveen@moneyreminder.app',
                          password: 'password123',
                          icon: Icons.flash_on_rounded,
                          accent: const Color(0xFF818CF8),
                          isDark: isDark,
                        ),
                        _buildDemoPill(
                          label: 'Demo Admin',
                          email: 'admin@moneyreminder.app',
                          password: 'password123',
                          icon: Icons.security_rounded,
                          accent: const Color(0xFF38BDF8),
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Main Frosted Glass Card
                    AuthGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email / Phone Field
                          AuthInputField(
                            controller: _emailCtrl,
                            label: AuthContentData.loginEmailLabel,
                            hint: AuthContentData.loginEmailHint,
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 12),

                          // Password Field
                          AuthInputField(
                            controller: _passCtrl,
                            label: AuthContentData.loginPasswordLabel,
                            hint: AuthContentData.loginPasswordHint,
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

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                          activeColor: AppTheme.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          AuthContentData.rememberMe,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  AuthContentData.forgotPassword,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Sign In Primary CTA Button
                          AuthPrimaryButton(
                            label: 'Sign In to Vault',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            icon: Icons.arrow_forward_rounded,
                          ),

                          const SizedBox(height: 16),

                          // Symmetrical OR Divider
                          const AuthDivider(label: AuthContentData.orContinueWith),

                          const SizedBox(height: 14),

                          // Fast Authentication Grid
                          Row(
                            children: [
                              Expanded(
                                child: AuthSocialButton(
                                  label: 'Google',
                                  iconWidget: Container(
                                    width: 19,
                                    height: 19,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    child: Text(
                                      'G',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFEA4335),
                                      ),
                                    ),
                                  ),
                                  onTap: _handleExploreApp,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AuthSocialButton(
                                  label: 'Biometrics',
                                  iconWidget: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 19,
                                    color: AppTheme.primary,
                                  ),
                                  onTap: _handleExploreApp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Don't have an account? Sign Up Link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: AuthContentData.dontHaveAccount,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          children: [
                            TextSpan(
                              text: AuthContentData.createAccountLink,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Security Architecture Tagline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 11,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Zero-Knowledge Vault • Money Reminder',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoPill({
    required String label,
    required String email,
    required String password,
    required IconData icon,
    required Color accent,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _prefillDemoCredentials(email, password, label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withAlpha(isDark ? 35 : 20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withAlpha(isDark ? 90 : 45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: accent),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$label: $email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? accent : const Color(0xFF3730A3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
