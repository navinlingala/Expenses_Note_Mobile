import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/investment_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/gold_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/credit_card_provider.dart';
import '../../providers/vault_provider.dart';
import '../../widgets/whatsapp_button.dart';
import 'cashflow_detail_screen.dart';
import 'receivables_detail_screen.dart';
import 'payables_detail_screen.dart';
import 'overdue_payments_screen.dart';
import '../loans/loan_list_screen.dart';
import '../loans/add_loan_screen.dart';
import '../people/add_due_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../investments/investment_list_screen.dart';
import '../gold/gold_portfolio_screen.dart';
import '../child/child_hub_screen.dart';
import '../child/add_edit_child_expense_screen.dart';
import '../credit_cards/credit_cards_hub_screen.dart';
import '../credit_cards/add_edit_credit_card_screen.dart';
import '../vault/vault_hub_screen.dart';
import '../vault/add_edit_vault_item_screen.dart';
import '../income/family_income_screen.dart';
import '../calculators/calculators_screen.dart';
import '../trash/trash_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const DashboardScreen({super.key, this.onOpenDrawer});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Future<void> _openWhatsAppSupport(BuildContext context) async {
    const supportNumber = '919010067464';
    final url = Uri.parse('https://wa.me/$supportNumber?text=${Uri.encodeComponent("Hello Expenses Note Support, I need assistance with the app.")}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp support.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loanProv = context.watch<LoanProvider>();
    final txProv = context.watch<TransactionProvider>();
    final invProv = context.watch<InvestmentProvider>();
    final incProv = context.watch<IncomeProvider>();
    final goldProv = context.watch<GoldProvider>();
    final childProv = context.watch<ChildProvider>();
    final creditCardProv = context.watch<CreditCardProvider>();
    final vaultProv = context.watch<VaultProvider>();

    final totalReceive = txProv.totalToReceive + invProv.totalExpectedMonthlyReturn;
    final totalPay = txProv.totalToPay + loanProv.totalMonthlyEmis;
    final totalEmi = loanProv.totalMonthlyEmis;

    final monthlyCredit = txProv.monthlyCredit;
    final monthlyDebit = txProv.monthlyDebit;
    final monthlyReceivable = txProv.monthlyReceivable;
    final monthlyPayable = txProv.monthlyPayable;

    final totalHouseholdSalary = incProv.totalMonthlyIncome;
    final monthlyInflow = totalHouseholdSalary + monthlyCredit + invProv.totalExpectedMonthlyReturn + monthlyReceivable;
    final monthlyOutflow = monthlyDebit + totalEmi + monthlyPayable;
    final netCashflow = monthlyInflow - monthlyOutflow;

    // Financial Health Calculation
    int healthScore = 50;
    if (monthlyInflow > 0) {
      final savingsRate = (netCashflow / monthlyInflow) * 100;
      final emiRatio = (totalEmi / monthlyInflow) * 100;

      if (savingsRate >= 30 && emiRatio <= 35) {
        healthScore = 90;
      } else if (savingsRate >= 15 && emiRatio <= 50) {
        healthScore = 75;
      } else if (netCashflow > 0) {
        healthScore = 60;
      } else {
        healthScore = 40;
      }
    }

    final upcomingTxs = txProv.upcomingTransactions;
    final overdueTxs = txProv.overdueTransactions;
    final activeLoans = loanProv.activeLoans;
    final user = context.watch<AuthProvider>().currentUser;

    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good morning';
      if (hour < 17) return 'Good afternoon';
      return 'Good evening';
    }

    final greeting = getGreeting();
    final displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim().split(' ').first
        : 'Finance Note';
    final userInitial = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // 1. Premium User Avatar & Drawer Trigger
                  InkWell(
                    onTap: () {
                      if (widget.onOpenDrawer != null) {
                        widget.onOpenDrawer!();
                      } else {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withAlpha(isDark ? 60 : 40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF6366F1),
                              child: Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.menu_rounded,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 2. Personalized Title & Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$greeting ✨',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black54,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),

                  // 3. Ultra-Premium Top Bar Actions (Alert Bell & Secret Vault)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Alert Notification Bell
                      _buildHeaderGlassButton(
                        context: context,
                        isDark: isDark,
                        icon: Icons.notifications_none_rounded,
                        tooltip: 'Overdue & Alerts',
                        badgeCount: overdueTxs.length,
                        badgeColor: const Color(0xFFF43F5E),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OverduePaymentsScreen()),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Secure Personal Vault
                      _buildHeaderGlassButton(
                        context: context,
                        isDark: isDark,
                        icon: Icons.shield_outlined,
                        tooltip: 'Personal Secret Vault',
                        badgeCount: vaultProv.totalSecretsCount,
                        badgeColor: const Color(0xFF6366F1),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VaultHubScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: () async {
            final uid = context.read<AuthProvider>().currentUser?.id;
            if (uid != null) {
              await loanProv.loadLoans(uid);
              await txProv.loadTransactions(uid);
              await invProv.loadInvestments(uid);
              await incProv.loadIncomes(uid);
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. ELITE CASHFLOW HERO CARD (Interactive)
              _buildHeroCashflowCard(
                context: context,
                isDark: isDark,
                netCashflow: netCashflow,
                monthlyInflow: monthlyInflow,
                monthlyOutflow: monthlyOutflow,
                totalHouseholdSalary: totalHouseholdSalary,
                healthScore: healthScore,
              ),

              const SizedBox(height: 14),

              // 2. QUICK ACTION POWER HUB (Clean Modern Pills)
              _buildQuickActionsHub(context, isDark),

              const SizedBox(height: 16),

              // 3. KEY METRICS TRIO CARDS
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: 'To Receive',
                      amount: totalReceive,
                      icon: Icons.call_received_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReceivablesDetailScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: 'To Pay',
                      amount: totalPay,
                      icon: Icons.call_made_rounded,
                      color: const Color(0xFFF43F5E),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PayablesDetailScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      context: context,
                      title: 'Monthly EMIs',
                      amount: totalEmi,
                      icon: Icons.account_balance_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoanListScreen()),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. OVERDUE ALERT (If any)
              if (overdueTxs.isNotEmpty) ...[
                _buildOverdueAlertBanner(context, isDark, overdueTxs.length),
                const SizedBox(height: 16),
              ],

              // 5. WEALTH & INVESTMENTS PORTFOLIO STRIP
              _buildInvestmentPortfolioStrip(context, isDark, invProv),

              const SizedBox(height: 12),

              // 5.1 GOLD ASSETS & SGB WEALTH STRIP
              _buildGoldPortfolioStrip(context, isDark, goldProv),

              const SizedBox(height: 12),

              // 5.2 KIDS & CHILD FINANCE STRIP
              _buildKidsFinanceStrip(context, isDark, childProv),

              const SizedBox(height: 12),

              // 5.3 CREDIT CARDS & BILL REMINDERS STRIP
              _buildCreditCardsPortfolioStrip(context, isDark, creditCardProv),

              const SizedBox(height: 12),

              // 5.4 SECURE PERSONAL SECRET VAULT STRIP
              _buildVaultPortfolioStrip(context, isDark, vaultProv),

              const SizedBox(height: 18),

              // 6. SECTION HEADER & UPCOMING SCHEDULE
              _buildSectionHeader(
                title: 'Upcoming & Due Payments',
                countBadge: upcomingTxs.length,
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PayablesDetailScreen()),
                ),
              ),
              const SizedBox(height: 8),

              if (upcomingTxs.isEmpty)
                _buildEmptyUpcomingPlaceholder(isDark)
              else
                ...upcomingTxs.take(3).map((tx) => _buildTransactionTile(context, isDark, tx)),

              const SizedBox(height: 18),

              // 7. ACTIVE LOANS & EMIS SNAPSHOT
              _buildSectionHeader(
                title: 'Active Loans Snapshot',
                countBadge: activeLoans.length,
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoanListScreen()),
                ),
              ),
              const SizedBox(height: 8),

              if (activeLoans.isEmpty)
                _buildEmptyLoansPlaceholder(context, isDark)
              else
                ...activeLoans.take(2).map((loan) => _buildLoanTile(context, isDark, loan)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER GLASS ACTION BUTTON ---
  Widget _buildHeaderGlassButton({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int badgeCount = 0,
    Color badgeColor = const Color(0xFFF43F5E),
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 35 : 12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. HERO CASHFLOW CARD ---
  Widget _buildHeroCashflowCard({
    required BuildContext context,
    required bool isDark,
    required double netCashflow,
    required double monthlyInflow,
    required double monthlyOutflow,
    required double totalHouseholdSalary,
    required int healthScore,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CashflowDetailScreen()),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        netCashflow >= 0 ? 'Surplus Positive' : 'Deficit Alert',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(60),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Health: $healthScore%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Net Monthly Savings & Balance',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${netCashflow >= 0 ? "+" : "-"}${CurrencyFormatter.format(netCashflow.abs())}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.south_west_rounded, color: Color(0xFF34D399), size: 14),
                          SizedBox(width: 4),
                          Text('Total Inflow', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(monthlyInflow),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.north_east_rounded, color: Color(0xFFF87171), size: 14),
                          SizedBox(width: 4),
                          Text('Total Outflow', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(monthlyOutflow),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. QUICK ACTIONS POWER HUB ---
  Widget _buildQuickActionsHub(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionPill(
            context: context,
            isDark: isDark,
            label: '+ Loan',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen())),
          ),
          const SizedBox(width: 8),
          _actionPill(
            context: context,
            isDark: isDark,
            label: '+ Due to Pay/Get',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF10B981),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDueScreen())),
          ),
          const SizedBox(width: 8),
          _actionPill(
            context: context,
            isDark: isDark,
            label: '+ Daily Expense',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
          ),
          const SizedBox(width: 8),
          _actionPill(
            context: context,
            isDark: isDark,
            label: '+ Child Exp',
            icon: Icons.child_care_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildHubScreen())),
          ),
          const SizedBox(width: 8),
          _actionPill(
            context: context,
            isDark: isDark,
            label: '+ Credit Card',
            icon: Icons.credit_card_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditCardsHubScreen())),
          ),
          const SizedBox(width: 8),
          _actionPill(
            context: context,
            isDark: isDark,
            label: '+ Gold Asset',
            icon: Icons.shield_outlined,
            color: const Color(0xFFEAB308),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoldPortfolioScreen())),
          ),
          const SizedBox(width: 8),
          _actionPill(
            context: context,
            isDark: isDark,
            label: '+ Salary / Income',
            icon: Icons.payments_rounded,
            color: const Color(0xFF059669),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyIncomeScreen())),
          ),
          const SizedBox(width: 8),
          _actionPill(
            context: context,
            isDark: isDark,
            label: 'SIP & EMI Calc',
            icon: Icons.calculate_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required BuildContext context,
    required bool isDark,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- 3. KEY METRICS CARD ---
  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. OVERDUE ALERT BANNER ---
  Widget _buildOverdueAlertBanner(BuildContext context, bool isDark, int count) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OverduePaymentsScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF43F5E).withAlpha(isDark ? 25 : 18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF43F5E).withAlpha(isDark ? 90 : 60), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Overdue Payment${count > 1 ? "s" : ""} Pending!',
                      style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view, update status, settle or reschedule dues.',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFF43F5E)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. INVESTMENT PORTFOLIO STRIP ---
  Widget _buildInvestmentPortfolioStrip(BuildContext context, bool isDark, InvestmentProvider invProv) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InvestmentListScreen()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.savings_rounded, color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Investments & Wealth', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatter.format(invProv.totalCurrentValue)} • +${CurrencyFormatter.format(invProv.totalExpectedMonthlyReturn)}/mo',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (invProv.isOverallProfitable ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${invProv.isOverallProfitable ? "+" : ""}${invProv.overallGainPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: invProv.isOverallProfitable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- 5.1 GOLD ASSETS & SGB STRIP ---
  Widget _buildGoldPortfolioStrip(BuildContext context, bool isDark, GoldProvider goldProv) {
    final hasGold = goldProv.assets.isNotEmpty;
    final totalGrams = goldProv.totalGoldWeightGrams;
    final totalVal = goldProv.totalCurrentMarketValue;
    final gain = goldProv.totalAbsoluteGain;
    final gainPercent = goldProv.totalGainPercentage;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GoldPortfolioScreen()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAB308).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308).withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFFEAB308), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gold Assets & SGB', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    hasGold
                        ? '${totalGrams.toStringAsFixed(1)}g (${goldProv.totalGoldWeightTolas.toStringAsFixed(1)} Tola) • ${CurrencyFormatter.format(totalVal)}'
                        : 'Track physical jewelry, coins & SGB bonds',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
            if (hasGold)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (gain >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${gain >= 0 ? "+" : ""}${gainPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: gain >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Gold Vault',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEAB308),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- 5.2 KIDS & CHILD FINANCE STRIP ---
  Widget _buildKidsFinanceStrip(BuildContext context, bool isDark, ChildProvider childProv) {
    final hasKids = childProv.profiles.isNotEmpty;
    final totalInvested = childProv.totalCurrentValuation;
    final monthlySpend = childProv.totalMonthlyChildExpenses;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChildHubScreen()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3B82F6).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.child_care_rounded, color: Color(0xFF3B82F6), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kids Wealth & Child Care', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    hasKids
                        ? '${childProv.profiles.length} Kids • Spend: ${CurrencyFormatter.format(monthlySpend)}/mo • Wealth: ${CurrencyFormatter.format(totalInvested)}'
                        : 'Track school fees, pediatric care, SSY & education funds',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hasKids ? '${childProv.profiles.length} Kids' : 'Kids Hub',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- 5.3 CREDIT CARDS & BILL REMINDER STRIP ---
  Widget _buildCreditCardsPortfolioStrip(BuildContext context, bool isDark, CreditCardProvider creditCardProv) {
    final hasCards = creditCardProv.cards.isNotEmpty;
    final totalOutstanding = creditCardProv.totalCurrentOutstanding;
    final totalLimit = creditCardProv.totalCreditLimit;
    final utilization = creditCardProv.overallUtilizationPercentage;
    final health = creditCardProv.overallUtilizationHealth;
    final healthColor = health == 'HEALTHY'
        ? const Color(0xFF10B981)
        : (health == 'MODERATE' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreditCardsHubScreen()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.credit_card_rounded, color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Credit Cards & Bill Cycles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    hasCards
                        ? '${creditCardProv.cards.length} Cards • Due: ${CurrencyFormatter.format(totalOutstanding)} / ${CurrencyFormatter.format(totalLimit)}'
                        : 'Track card limits, statement dates & pay reminders',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
            if (hasCards)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${utilization.toStringAsFixed(0)}% Used',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: healthColor,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Cards Hub',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- 5.4 SECURE PERSONAL SECRET VAULT STRIP ---
  Widget _buildVaultPortfolioStrip(BuildContext context, bool isDark, VaultProvider vaultProv) {
    final hasSecrets = vaultProv.totalSecretsCount > 0;
    final totalSecrets = vaultProv.totalSecretsCount;
    final isLocked = !vaultProv.isVaultUnlocked;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VaultHubScreen()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF06B6D4).withAlpha(70)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF06B6D4), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Personal Secret Vault', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(width: 6),
                      Icon(isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 13, color: isLocked ? Colors.orange : const Color(0xFF10B981)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSecrets
                        ? '$totalSecrets Secret items stored • ${vaultProv.cardsCount} Cards, ${vaultProv.bankAccountsCount} Banks, ${vaultProv.passwordsCount} PINs'
                        : 'Securely store Card CVVs, ATM PINs, Bank Accounts & Passwords',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hasSecrets ? '$totalSecrets Items' : 'Open Vault',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF06B6D4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- SECTION HEADERS ---
  Widget _buildSectionHeader({
    required String title,
    required int countBadge,
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            if (countBadge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$countBadge', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
              ),
            ],
          ],
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
        ),
      ],
    );
  }

  // --- EMPTY PLACEHOLDERS ---
  Widget _buildEmptyUpcomingPlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withAlpha(50) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          'No upcoming payments due in next 7 days 🎉',
          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyLoansPlaceholder(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withAlpha(50) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('No active loans registered', style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen())),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add Loan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- TILES ---
  Widget _buildTransactionTile(BuildContext context, bool isDark, dynamic tx) {
    final isPayable = tx.type == 'PAYABLE';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: (isPayable ? const Color(0xFFF43F5E) : const Color(0xFF10B981)).withAlpha(25),
          child: Icon(
            isPayable ? Icons.call_made_rounded : Icons.call_received_rounded,
            color: isPayable ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
            size: 18,
          ),
        ),
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
          '${tx.personName ?? "General"} • Due: ${AppDateUtils.formatShort(tx.dueDate)}',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.format(tx.amount),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: isPayable ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
              ),
            ),
            if (tx.phoneNumber != null && tx.phoneNumber!.trim().isNotEmpty) ...[
              const SizedBox(width: 6),
              WhatsAppButton(
                phoneNumber: tx.phoneNumber!,
                personName: tx.personName ?? 'Friend',
                amount: tx.amount,
                dueDate: tx.dueDate,
                note: tx.title,
                isCompact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTile(BuildContext context, bool isDark, dynamic loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B5CF6).withAlpha(25),
          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF8B5CF6), size: 18),
        ),
        title: Text(loan.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
          '${loan.lenderName} • ${loan.remainingEmis}/${loan.totalEmis} EMIs left',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(loan.emiAmount),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF8B5CF6)),
            ),
            const Text('/ mo', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
