import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../auth/login_screen.dart';
import 'models/onboarding_model.dart';
import 'widgets/onboarding_cards.dart';
import 'widgets/onboarding_page_indicator.dart';
import 'widgets/splash_view.dart';

/// Fully interactive, multi-step 3D glassmorphic onboarding journey.
/// Bulletproof layout that dynamically adapts to mobile, desktop, and resized web viewports without overflow.
class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingFlowScreen({super.key, this.onComplete});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0 = Splash, 1..4 = Onboarding Slides
  late final PageController _pageController;
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;

  final List<OnboardingPageModel> _pages = OnboardingDataRepository.getPages();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _nextPage() {
    final pageIndex = _currentStep - 1;
    if (pageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _prevPage() {
    final pageIndex = _currentStep - 1;
    if (pageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return PremiumSplashView(
        onContinue: () {
          if (mounted) {
            setState(() => _currentStep = 1);
          }
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageIndex = (_currentStep - 1).clamp(0, _pages.length - 1);
    final currentPage = _pages[pageIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top Navigation & Step Indicator Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // App Emblem & Name
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: currentPage.gradientColors),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: currentPage.accentColor.withAlpha(100),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(currentPage.icon, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppConstants.appName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Page Dots Indicator
                      OnboardingPageIndicator(
                        totalCount: _pages.length,
                        currentIndex: pageIndex,
                        activeColor: currentPage.accentColor,
                      ),

                      const Spacer(),

                      // Skip Button
                      TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page Content (Slides 0 to 3)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index + 1;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildSlidePage(_pages[index], isDark);
                    },
                  ),
                ),

                // Bottom Actions Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _buildBottomActions(pageIndex, currentPage, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlidePage(OnboardingPageModel page, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),

              // Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: page.accentColor.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: page.accentColor.withAlpha(isDark ? 90 : 50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(page.icon, size: 13, color: page.accentColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        page.badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: page.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3D Glassmorphic Interactive Visual Card
              _buildVisualCard(page.stepIndex),

              const SizedBox(height: 16),

              // Feature Bullet Points
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: page.bulletPoints.map((bullet) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: page.accentColor.withAlpha(isDark ? 40 : 25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: page.accentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bullet,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCard(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return ExpenseIntelligenceVisualCard(floatingAnimation: _floatingAnimation);
      case 1:
        return WhatsAppReminderVisualCard(floatingAnimation: _floatingAnimation);
      case 2:
        return PeopleDuesVisualCard(floatingAnimation: _floatingAnimation);
      case 3:
      default:
        return WealthGrowthVisualCard(floatingAnimation: _floatingAnimation);
    }
  }

  Widget _buildBottomActions(
    int pageIndex,
    OnboardingPageModel currentPage,
    bool isDark,
  ) {
    final isLastPage = pageIndex == _pages.length - 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Back Button (hidden on page 0)
                if (pageIndex > 0) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: IconButton(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      tooltip: 'Back',
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Main CTA Button
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentPage.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: currentPage.accentColor.withAlpha(120),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLastPage ? 'Get Started Now' : 'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isLastPage ? Icons.bolt_rounded : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Quick Sign In Link on the last page
            if (isLastPage) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _goToLogin,
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: currentPage.accentColor,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
