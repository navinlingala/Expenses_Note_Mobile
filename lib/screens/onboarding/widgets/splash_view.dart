import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../onboarding_assets_data.dart';

/// Premium animated luxury splash view with ambient glow canvas and smart status ticker.
class PremiumSplashView extends StatefulWidget {
  final VoidCallback onContinue;

  const PremiumSplashView({super.key, required this.onContinue});

  @override
  State<PremiumSplashView> createState() => _PremiumSplashViewState();
}

class _PremiumSplashViewState extends State<PremiumSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  int _statusIndex = 0;

  final List<String> _loadingStatuses = [
    'Initializing Secure Financial Ledger...',
    'Loading EMI & Debt Tracking Engine...',
    'Synchronizing WhatsApp Automation...',
    'Encrypting Local Data Vault (AES-256)...',
    'Ready to Launch Money Reminder App...',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startStatusTicker();
  }

  void _startStatusTicker() async {
    for (int i = 0; i < _loadingStatuses.length; i++) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _statusIndex = i);
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    widget.onContinue();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStatus = _loadingStatuses[_statusIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: GestureDetector(
        onTap: widget.onContinue,
        child: Stack(
          children: [
            // Ambient Procedural Glowing Orbs
            Positioned.fill(
              child: CustomPaint(
                painter: _AmbientGlowPainter(isDark: isDark),
              ),
            ),

            // Main Splash Content with LayoutBuilder & SingleChildScrollView
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // Glowing Central Emblem with Pulsing Aura
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _glowAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _glowAnimation.value,
                                        child: Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF6366F1).withAlpha(isDark ? 90 : 50),
                                                blurRadius: 45,
                                                spreadRadius: 10,
                                              ),
                                              BoxShadow(
                                                color: const Color(0xFF0EA5E9).withAlpha(isDark ? 80 : 40),
                                                blurRadius: 30,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Outer glowing frosted badge
                                  Container(
                                    width: 105,
                                    height: 105,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(isDark ? 40 : 180),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withAlpha(isDark ? 100 : 60),
                                          blurRadius: 36,
                                          offset: const Offset(0, 14),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFF0EA5E9).withAlpha(isDark ? 80 : 40),
                                          blurRadius: 20,
                                          offset: const Offset(0, -5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Image.memory(
                                        OnboardingAssets.splashLogo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_wallet_rounded,
                                            color: Colors.white,
                                            size: 44,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Brand App Name
                            Text(
                              AppConstants.appName,
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Subtitle Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withAlpha(isDark ? 35 : 20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withAlpha(isDark ? 80 : 40),
                                ),
                              ),
                              child: Text(
                                'Smart EMI & Wealth Intelligence',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Dynamic Loading Status Ticker
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? const Color(0xFF818CF8) : AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      currentStatus,
                                      key: ValueKey<String>(currentStatus),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Tap anywhere to skip',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ambient Glow Painter for luxury background atmosphere
class _AmbientGlowPainter extends CustomPainter {
  final bool isDark;

  _AmbientGlowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withAlpha(isDark ? 50 : 25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.25),
        radius: size.width * 0.6,
      ));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.25), size.width * 0.6, paint1);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0EA5E9).withAlpha(isDark ? 45 : 20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.75),
        radius: size.width * 0.7,
      ));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.75), size.width * 0.7, paint2);

    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF10B981).withAlpha(isDark ? 25 : 10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.5, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
