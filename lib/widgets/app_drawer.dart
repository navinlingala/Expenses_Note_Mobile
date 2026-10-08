import '../providers/income_provider.dart';
import '../providers/gold_provider.dart';
import '../providers/child_provider.dart';
import '../providers/credit_card_provider.dart';
import '../screens/gold/gold_portfolio_screen.dart';
import '../screens/child/child_hub_screen.dart';
import '../screens/credit_cards/credit_cards_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/investment_provider.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/trash/trash_screen.dart';
import '../core/utils/currency_formatter.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Expenses Note',
      applicationVersion: 'v2.1.0 (Production Build)',
      applicationIcon: const CircleAvatar(
        backgroundColor: Color(0xFF6366F1),
        child: Icon(Icons.wallet_rounded, color: Colors.white),
      ),
      children: const [
        Text(
          'Expenses Note is an offline-first financial management system designed to track Personal Loans, People Dues, Investments, Daily Outflows, and Automated WhatsApp Reminders.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isGuest = auth.isGuest;

    final loanProv = context.watch<LoanProvider>();
    final txProv = context.watch<TransactionProvider>();
    final invProv = context.watch<InvestmentProvider>();
    final incProv = context.watch<IncomeProvider>();

    final totalTrashCount = loanProv.deletedLoans.length +
        txProv.deletedTransactions.length +
        invProv.deletedInvestments.length;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Header with Clickable Account Screen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFFEEF2FF), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? 'Expenses User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isGuest) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                                  ),
                                  child: const Text(
                                    'GUEST',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? 'Tap to view profile',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit Profile',
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Quick Data Sync / Refresh Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: InkWell(
                onTap: () {
                  final uid = user?.id;
                  if (uid != null) {
                    loanProv.loadLoans(uid);
                    txProv.loadTransactions(uid);
                    invProv.loadInvestments(uid);
                    incProv.loadIncomes(uid);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data refreshed and synced!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync_rounded, color: Color(0xFF6366F1), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sync & Refresh Data',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Feature Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text('CORE MODULES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    subtitle: 'Overview & Monthly Cashflow',
                    isSelected: selectedIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(0);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.payments_rounded,
                    title: 'Salary & Family Earnings',
                    subtitle: 'Total: ${CurrencyFormatter.format(incProv.totalMonthlyIncome)}/mo',
                    badgeCount: incProv.activeIncomes.length,
                    badgeColor: const Color(0xFF10B981),
                    isSelected: selectedIndex == 7,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(7);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.account_balance_rounded,
                    title: 'Personal Loans & EMIs',
                    subtitle: '${loanProv.activeLoans.length} Active Loans Tracker',
                    badgeCount: loanProv.activeLoans.length,
                    badgeColor: const Color(0xFF6366F1),
                    isSelected: selectedIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(1);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    title: 'People Dues & Debts',
                    subtitle: 'Receivables & Payables Ledger',
                    badgeCount: txProv.pendingReceivables.length + txProv.pendingPayables.length,
                    badgeColor: const Color(0xFF10B981),
                    isSelected: selectedIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(2);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.savings_rounded,
                    title: 'Investments & Wealth',
                    subtitle: '${invProv.investments.length} Active Portfolios',
                    badgeCount: invProv.investments.length,
                    badgeColor: const Color(0xFF3B82F6),
                    isSelected: selectedIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(3);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Gold Assets & SGB',
                    subtitle: '${context.watch<GoldProvider>().totalGoldWeightGrams.toStringAsFixed(1)}g Total Holding',
                    badgeCount: context.watch<GoldProvider>().assets.length,
                    badgeColor: const Color(0xFFEAB308),
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GoldPortfolioScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.child_care_rounded,
                    title: 'Kids Wealth & Care',
                    subtitle: 'Child Expenses, SSY & Goals',
                    badgeCount: context.watch<ChildProvider>().profiles.length,
                    badgeColor: const Color(0xFF3B82F6),
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChildHubScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.credit_card_rounded,
                    title: 'Credit Cards & Bills',
                    subtitle: 'Usages, Cycles & Reminders',
                    badgeCount: context.watch<CreditCardProvider>().cards.length,
                    badgeColor: const Color(0xFF6366F1),
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreditCardsHubScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Daily Expenses Note',
                    subtitle: 'Day-to-day spending tracker',
                    isSelected: selectedIndex == 4,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(4);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('FINANCIAL TOOLS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calculate_rounded,
                    title: 'Loan & SIP Calculators',
                    subtitle: 'EMI, SIP & Lump Sum Visual Planner',
                    isSelected: selectedIndex == 8,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(8);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    title: 'Cashflow Analytics',
                    subtitle: 'In-Out cash movement log',
                    isSelected: selectedIndex == 5,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(5);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_rounded,
                    title: 'Settings & Notifications',
                    subtitle: 'WhatsApp alerts, alarm time, currency',
                    isSelected: selectedIndex == 6,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(6);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.delete_outline_rounded,
                    title: 'Trash / Recycle Bin',
                    subtitle: '$totalTrashCount items in bin',
                    badgeCount: totalTrashCount,
                    badgeColor: const Color(0xFFF43F5E),
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrashScreen()),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('SUPPORT & INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.chat_rounded,
                    title: 'Direct WhatsApp Support',
                    subtitle: 'Need help or feature request?',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _openWhatsAppSupport(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    title: 'About Expenses Note',
                    subtitle: 'Version 2.1.0 (Production)',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF43F5E),
                  side: const BorderSide(color: Color(0xFFF43F5E)),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(isGuest ? 'Exit Guest Mode' : 'Log Out'),
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
    Color? badgeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6366F1).withAlpha(isDark ? 50 : 25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF6366F1).withAlpha(80), width: 1)
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isDark ? Colors.white70 : Colors.black87),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        trailing: (badgeCount != null && badgeCount > 0)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
