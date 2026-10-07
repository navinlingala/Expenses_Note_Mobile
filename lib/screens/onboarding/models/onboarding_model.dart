import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Clean, strongly-typed model for Onboarding slides
class OnboardingPageModel {
  final int stepIndex;
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final List<String> bulletPoints;

  const OnboardingPageModel({
    required this.stepIndex,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.bulletPoints,
  });
}

/// Dynamic repository providing configured slides without inline hardcoding
class OnboardingDataRepository {
  static List<OnboardingPageModel> getPages() {
    return [
      OnboardingPageModel(
        stepIndex: 0,
        badge: 'CASHFLOW INTELLIGENCE',
        title: 'Master Every Rupee,\nTrack In Real Time',
        subtitle:
            'Effortlessly record daily expenses, categorize transactions, and visualize where your money moves every month.',
        icon: Icons.account_balance_wallet_rounded,
        accentColor: AppTheme.primary,
        gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        bulletPoints: [
          'Automatic daily categorization',
          'Live income vs expense trends',
          'Instant balance health check',
        ],
      ),
      OnboardingPageModel(
        stepIndex: 1,
        badge: 'WHATSAPP & EMI ALERTS',
        title: 'Zero Late Fees,\nInstant Smart Reminders',
        subtitle:
            'Never miss a credit card bill, rent, or EMI due date. Get timely alerts delivered directly to your WhatsApp & phone.',
        icon: Icons.notifications_active_rounded,
        accentColor: AppTheme.creditGreen,
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        bulletPoints: [
          'Automated WhatsApp notifications',
          'EMI countdown with zero delays',
          'One-tap payment confirmation',
        ],
      ),
      OnboardingPageModel(
        stepIndex: 2,
        badge: 'PEOPLE DUES & LOANS',
        title: 'Track Who Owes Who,\nSettle Up Effortlessly',
        subtitle:
            'Keep peer-to-peer loans transparent. Monitor money lent, dues to pay, partial installments, and clear balances easily.',
        icon: Icons.handshake_rounded,
        accentColor: AppTheme.secondary,
        gradientColors: [const Color(0xFF0EA5E9), const Color(0xFF2563EB)],
        bulletPoints: [
          'Friend & vendor ledgers',
          'Partial repayment tracking',
          'Polite WhatsApp reminder nudges',
        ],
      ),
      OnboardingPageModel(
        stepIndex: 3,
        badge: 'WEALTH & NET WORTH',
        title: 'Compound Your Wealth,\nAchieve Every Goal',
        subtitle:
            'Bring your mutual funds, gold, fixed deposits, and loans under one unified net worth dashboard that grows with you.',
        icon: Icons.trending_up_rounded,
        accentColor: AppTheme.warningOrange,
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        bulletPoints: [
          'Unified net worth trajectory',
          'Multi-asset portfolio distribution',
          'Actionable savings milestones',
        ],
      ),
    ];
  }

  /// Dynamic steps for splash loader
  static final List<String> splashStatusSteps = [
    'Initializing secure vault...',
    'Loading financial intelligence...',
    'Syncing smart reminder engine...',
    'Ready',
  ];
}
