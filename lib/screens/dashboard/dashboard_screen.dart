import '../../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/investment_provider.dart';
import '../investments/investment_list_screen.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/whatsapp_button.dart';
import 'cashflow_detail_screen.dart';
import 'receivables_detail_screen.dart';
import 'payables_detail_screen.dart';
import '../loans/loan_list_screen.dart';
import '../loans/add_loan_screen.dart';
import '../people/add_due_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../trash/trash_screen.dart';
import '../profile/user_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loanProv = context.watch<LoanProvider>();
    final txProv = context.watch<TransactionProvider>();
    final invProv = context.watch<InvestmentProvider>();

    final totalReceive = txProv.totalToReceive + invProv.totalExpectedMonthlyReturn;
    final totalPay = txProv.totalToPay + loanProv.totalMonthlyEmis;
    final totalEmi = loanProv.totalMonthlyEmis;

    final monthlyCredit = txProv.monthlyCredit;
    final monthlyDebit = txProv.monthlyDebit;
    final monthlyReceivable = txProv.monthlyReceivable;
    final monthlyPayable = txProv.monthlyPayable;

    final monthlyInflow = monthlyCredit + invProv.totalExpectedMonthlyReturn + monthlyReceivable;
    final monthlyOutflow = monthlyDebit + totalEmi + monthlyPayable;
    final netCashflow = monthlyInflow - monthlyOutflow;

    final upcomingTxs = txProv.upcomingTransactions;
    final overdueTxs = txProv.overdueTransactions;
    final activeLoans = loanProv.activeLoans;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Money Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              AppDateUtils.formatMonthYear(DateTime.now().year, DateTime.now().month),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final uid = context.read<AuthProvider>().currentUser?.id;
              if (uid != null) {
                loanProv.loadLoans(uid);
                txProv.loadTransactions(uid);
                invProv.loadInvestments(uid);
              }
            },
          ),
          IconButton(
            tooltip: 'My Profile & Account',
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                (context.watch<AuthProvider>().currentUser?.name.isNotEmpty == true)
                    ? context.watch<AuthProvider>().currentUser!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = context.read<AuthProvider>().currentUser?.id;
          if (uid != null) {
            await loanProv.loadLoans(uid);
            await txProv.loadTransactions(uid);
                invProv.loadInvestments(uid);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Hero Cashflow Card (Interactive)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashflowDetailScreen()),
              ),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha(80),
                      blurRadius: 16,
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
                        const Text(
                          'Monthly Cashflow Status',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            netCashflow >= 0 ? '✓ Net Surplus' : '⚠ Net Deficit',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${netCashflow >= 0 ? "+" : "-"}${CurrencyFormatter.format(netCashflow.abs())}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _cashflowItem('Receive / Inflow', CurrencyFormatter.format(monthlyInflow), Icons.arrow_downward_rounded, const Color(0xFF34D399)),
                        const SizedBox(width: 16),
                        _cashflowItem('Pay / Outflow', CurrencyFormatter.format(monthlyOutflow), Icons.arrow_upward_rounded, const Color(0xFFF87171)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tap for full monthly breakdown',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Investments & Wealth Card (Interactive)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvestmentListScreen()),
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withAlpha(60),
                  ),
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
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.savings_rounded, color: Color(0xFF6366F1), size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Investments Portfolio',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InvestmentListScreen()),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Valuation', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(invProv.totalCurrentValue),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Est. Monthly Return', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              '+${CurrencyFormatter.format(invProv.totalExpectedMonthlyReturn)} / mo',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ],
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
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 2. Primary 3-Stat Summary Cards (Interactive with Detail Navigation)
            Row(
              children: [
                StatCard(
                  title: 'To Receive',
                  amount: CurrencyFormatter.format(totalReceive),
                  icon: Icons.call_received_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReceivablesDetailScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                StatCard(
                  title: 'To Pay',
                  amount: CurrencyFormatter.format(totalPay),
                  icon: Icons.call_made_rounded,
                  color: const Color(0xFFF43F5E),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PayablesDetailScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                StatCard(
                  title: 'EMIs / Mo',
                  amount: CurrencyFormatter.format(totalEmi),
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoanListScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 3. Overdue Alert Banner (if any)
            if (overdueTxs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF43F5E).withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${overdueTxs.length} Overdue Payment${overdueTxs.length > 1 ? "s" : ""}!',
                            style: const TextStyle(
                              color: Color(0xFFF43F5E),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Please review pending amounts to keep records accurate.',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 4. Quick Actions Row
            Row(
              children: [
                _quickActionButton(
                  context,
                  label: '+ Loan / EMI',
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddLoanScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _quickActionButton(
                  context,
                  label: '+ Money Owed',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddDueScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _quickActionButton(
                  context,
                  label: '+ Transaction',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 5. Active Loans & Upcoming EMIs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Loans & EMIs',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${activeLoans.length} Active',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (activeLoans.isEmpty)
              _emptyNotice('No active loans currently. Tap "+ Loan / EMI" to track one.')
            else
              ...activeLoans.map((loan) => _loanCard(context, loan, isDark)),

            const SizedBox(height: 24),

            // 6. Upcoming Reminders (7-day timeline)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Reminders (7 Days)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${upcomingTxs.length} items',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (upcomingTxs.isEmpty)
              _emptyNotice('No upcoming dues within the next 7 days.')
            else
              ...upcomingTxs.map((tx) => _upcomingTile(context, tx, isDark)),

            const SizedBox(height: 24),

            // 7. Recycle Bin & Trash Tracker
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trash & Deleted Items',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (loanProv.deletedLoans.length + txProv.deletedTransactions.length) > 0
                                ? ' items in trash - Tap to restore or delete permanently'
                                : 'Recycle bin is empty. Deleted items are stored safely here.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _cashflowItem(String title, String amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Text(amount, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loanCard(BuildContext context, dynamic loan, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      loan.lenderName,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${CurrencyFormatter.format(loan.emiAmount)} / mo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    Text(
                      'Due ${loan.dueDay}th of month',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: loan.progressPercentage,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: ${loan.paidEmis} / ${loan.totalEmis} EMIs',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
                Text(
                  'Remaining: ${loan.remainingEmis} EMIs (${CurrencyFormatter.format(loan.remainingBalance)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showPayEmiDialog(context, loan);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Pay This Month EMI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingTile(BuildContext context, dynamic tx, bool isDark) {
    final isReceivable = tx.type == 'RECEIVABLE';
    final color = isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      if (tx.personName != null)
                        Text(
                          'Person: ${tx.personName}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      Text(
                        AppDateUtils.getRelativeDueDate(tx.dueDate),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tx.isDueToday ? const Color(0xFFF59E0B) : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(tx.amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        context.read<TransactionProvider>().markAsCompleted(tx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isReceivable ? 'Mark Received' : 'Mark Paid',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isReceivable && tx.phoneNumber != null && tx.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  WhatsAppButton(
                    personName: tx.personName ?? tx.title,
                    phoneNumber: tx.phoneNumber!,
                    amount: tx.amount,
                    dueDate: tx.dueDate,
                    note: tx.notes,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showPayEmiDialog(BuildContext context, dynamic loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay ${loan.title} EMI'),
        content: Text(
          'Confirm payment of ${CurrencyFormatter.format(loan.emiAmount)} for EMI #${loan.paidEmis + 1} of ${loan.totalEmis}?\n\nThis will record the payment and advance remaining tenure to ${loan.remainingEmis - 1}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LoanProvider>().payEmi(loan: loan);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('EMI payment recorded for ${loan.title} ✅'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }
}

