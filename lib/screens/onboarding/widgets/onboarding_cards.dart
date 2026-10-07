import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// 1. Visual Card for Slide 0: Expense & Cashflow Intelligence
class ExpenseIntelligenceVisualCard extends StatelessWidget {
  final Animation<double> floatingAnimation;

  const ExpenseIntelligenceVisualCard({
    super.key,
    required this.floatingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final currency = AppConstants.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, floatingAnimation.value * 5),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.white, const Color(0xFFF1F5F9)],
          ),
          border: Border.all(
            color: const Color(0xFF6366F1).withAlpha(isDark ? 80 : 50),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withAlpha(isDark ? 50 : 35),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Chip + Status (Wrapped with Expanded to prevent overflow)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withAlpha(100),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL SPENDING',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$currency 48,250.00',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Monthly trend badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_down_rounded, color: Color(0xFF10B981), size: 13),
                      SizedBox(width: 3),
                      Text(
                        '-12% saved',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Segmented Category Breakdown Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 9,
                child: Row(
                  children: [
                    Expanded(
                      flex: 42,
                      child: Container(color: const Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 33,
                      child: Container(color: const Color(0xFF0EA5E9)),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 25,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildCategoryPill('Shopping 42%', const Color(0xFF6366F1), isDark)),
                Flexible(child: _buildCategoryPill('Bills 33%', const Color(0xFF0EA5E9), isDark)),
                Flexible(child: _buildCategoryPill('Food 25%', const Color(0xFFF59E0B), isDark)),
              ],
            ),

            const SizedBox(height: 16),

            // Floating Mini Transaction Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155).withAlpha(120) : const Color(0xFFE2E8F0).withAlpha(180),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF6366F1), size: 13),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Supermarket',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Just now • Essentials',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-$currency 1,450',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.debitRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCategoryPill(String text, Color dotColor, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

/// 2. Visual Card for Slide 1: Instant WhatsApp & EMI Alerts
class WhatsAppReminderVisualCard extends StatelessWidget {
  final Animation<double> floatingAnimation;

  const WhatsAppReminderVisualCard({
    super.key,
    required this.floatingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final currency = AppConstants.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -floatingAnimation.value * 5),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F2B1D), const Color(0xFF0A1F16)]
                : [Colors.white, const Color(0xFFF0FDF4)],
          ),
          border: Border.all(
            color: const Color(0xFF10B981).withAlpha(isDark ? 90 : 60),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withAlpha(isDark ? 55 : 35),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // WhatsApp Header Banner (Wrapped with Expanded to prevent overflow)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25D366).withAlpha(120),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mark_chat_read_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WHATSAPP AUTOMATION',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Smart EMI Reminders',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Live Status Beacon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF25D366).withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(0xFF25D366), size: 7),
                      SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Color(0xFF25D366),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Realistic Upcoming Loan / EMI Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.home_work_rounded, color: Color(0xFF6366F1), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HDFC Home Loan EMI',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Due in 2 days • 24th Sep',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppTheme.warningOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$currency 24,850',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0x2294A3B8)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 13),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'WhatsApp notification sent',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Delivered',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. Visual Card for Slide 2: People Dues & Loan Management
class PeopleDuesVisualCard extends StatelessWidget {
  final Animation<double> floatingAnimation;

  const PeopleDuesVisualCard({
    super.key,
    required this.floatingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final currency = AppConstants.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, floatingAnimation.value * 4),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0C2740), const Color(0xFF091C30)]
                : [Colors.white, const Color(0xFFF0F9FF)],
          ),
          border: Border.all(
            color: const Color(0xFF0EA5E9).withAlpha(isDark ? 90 : 60),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withAlpha(isDark ? 55 : 35),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (Wrapped with Expanded to prevent overflow)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withAlpha(120),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.handshake_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DUES & RECEIVABLES',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Peer-to-Peer Ledger',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(80)),
                  ),
                  child: const Text(
                    '2 PENDING',
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Lent Card (Receivable)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 13),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rahul Sharma',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Text(
                                    'You Lent • 65% Repaid',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+$currency 15,000',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Borrowed Card (Payable)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF43F5E).withAlpha(60)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFF43F5E), size: 13),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priya Patel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const Text(
                                'You Borrowed • Due Soon',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFFF43F5E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-$currency 5,000',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4. Visual Card for Slide 3: Wealth & Net Worth Growth
class WealthGrowthVisualCard extends StatelessWidget {
  final Animation<double> floatingAnimation;

  const WealthGrowthVisualCard({
    super.key,
    required this.floatingAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final currency = AppConstants.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -floatingAnimation.value * 4),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF291B07), const Color(0xFF1E1303)]
                : [Colors.white, const Color(0xFFFFFBEB)],
          ),
          border: Border.all(
            color: const Color(0xFFF59E0B).withAlpha(isDark ? 90 : 60),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withAlpha(isDark ? 55 : 35),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (Wrapped with Expanded to prevent overflow)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withAlpha(120),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL NET WORTH',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$currency 14,80,000',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 11),
                      SizedBox(width: 2),
                      Text(
                        '+24.8% YoY',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Procedural Glowing Spline Graph
            SizedBox(
              height: 65,
              width: double.infinity,
              child: CustomPaint(
                painter: _GlowingSplineChartPainter(
                  strokeColor: const Color(0xFFF59E0B),
                  glowColor: const Color(0xFFF59E0B).withAlpha(60),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Asset Distribution Tags (Wrapped with Flexible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildAssetChip('Mutual Funds 55%', const Color(0xFF6366F1), isDark)),
                const SizedBox(width: 4),
                Flexible(child: _buildAssetChip('Gold 25%', const Color(0xFFF59E0B), isDark)),
                const SizedBox(width: 4),
                Flexible(child: _buildAssetChip('FDs 20%', const Color(0xFF10B981), isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildAssetChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Procedural Glowing Spline Painter for Net Worth Graph
class _GlowingSplineChartPainter extends CustomPainter {
  final Color strokeColor;
  final Color glowColor;

  _GlowingSplineChartPainter({required this.strokeColor, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.85),
      Offset(size.width * 0.2, size.height * 0.70),
      Offset(size.width * 0.4, size.height * 0.75),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.8, size.height * 0.35),
      Offset(size.width, size.height * 0.10),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    // Gradient Fill under curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [glowColor, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Main Stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Glowing End Point Node
    final lastPoint = points.last;
    canvas.drawCircle(
      lastPoint,
      7,
      Paint()..color = strokeColor.withAlpha(100),
    );
    canvas.drawCircle(
      lastPoint,
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
