import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/investment_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../investments/investment_list_screen.dart';
import '../loans/loan_list_screen.dart';
import '../people/people_dues_screen.dart';
import '../transactions/add_transaction_screen.dart';

class CashflowDetailScreen extends StatefulWidget {
  const CashflowDetailScreen({super.key});

  @override
  State<CashflowDetailScreen> createState() => _CashflowDetailScreenState();
}

class _CashflowDetailScreenState extends State<CashflowDetailScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _filterType = 'ALL'; // ALL, INFLOW, OUTFLOW

  void _prevMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear -= 1;
      } else {
        _selectedMonth -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear += 1;
      } else {
        _selectedMonth += 1;
      }
    });
  }

  Future<void> _pickMonthYear() async {
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Select Month & Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Year:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: tempYear,
                        items: List.generate(15, (i) => 2020 + i)
                            .map((y) => DropdownMenuItem(value: y, child: Text('')))
                            .toList(),
                        onChanged: (y) {
                          if (y != null) setDialogState(() => tempYear = y);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final m = index + 1;
                      final isSelected = m == tempMonth;
                      final monthName = DateFormat('MMM').format(DateTime(2026, m));
                      return ChoiceChip(
                        label: Text(monthName),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6366F1),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setDialogState(() => tempMonth = m);
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedYear = tempYear;
                      _selectedMonth = tempMonth;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProv = context.watch<TransactionProvider>();
    final loanProv = context.watch<LoanProvider>();
    final invProv = context.watch<InvestmentProvider>();

    // 1. Transactions for selected month
    final monthTxs = txProv.transactions.where((t) {
      return t.dueDate.year == _selectedYear && t.dueDate.month == _selectedMonth;
    }).toList();

    final creditsList = monthTxs.where((t) => t.type == 'CREDIT').toList();
    final debitsList = monthTxs.where((t) => t.type == 'DEBIT').toList();
    final receivablesList = monthTxs.where((t) => t.type == 'RECEIVABLE').toList();
    final payablesList = monthTxs.where((t) => t.type == 'PAYABLE').toList();

    final monthlyCredit = creditsList.fold(0.0, (s, t) => s + t.amount);
    final monthlyDebit = debitsList.fold(0.0, (s, t) => s + t.amount);
    final monthlyReceivables = receivablesList.fold(0.0, (s, t) => s + t.amount);
    final monthlyPayables = payablesList.fold(0.0, (s, t) => s + t.amount);

    // 2. Investment expected returns (Passive monthly income)
    final invMonthlyReturn = invProv.totalExpectedMonthlyReturn;

    // 3. Loan monthly EMIs
    final loanMonthlyEmis = loanProv.totalMonthlyEmis;

    // 4. Combined calculations
    final totalMonthlyInflow = monthlyCredit + invMonthlyReturn + monthlyReceivables;
    final totalMonthlyOutflow = monthlyDebit + loanMonthlyEmis + monthlyPayables;
    final netCashflow = totalMonthlyInflow - totalMonthlyOutflow;
    final isSurplus = netCashflow >= 0;

    final totalVolume = totalMonthlyInflow + totalMonthlyOutflow;
    final inflowRatio = totalVolume > 0 ? (totalMonthlyInflow / totalVolume).clamp(0.0, 1.0) : 0.5;

    // Filtered ledger
    List<TransactionModel> displayTxs = [];
    if (_filterType == 'INFLOW') {
      displayTxs = monthTxs.where((t) => t.type == 'CREDIT' || t.type == 'RECEIVABLE').toList();
    } else if (_filterType == 'OUTFLOW') {
      displayTxs = monthTxs.where((t) => t.type == 'DEBIT' || t.type == 'PAYABLE').toList();
    } else {
      displayTxs = monthTxs;
    }
    displayTxs.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Cashflow Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Choose Month / Year',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickMonthYear,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = context.read<AuthProvider>().currentUser?.id;
          if (uid != null) {
            await Future.wait([
              context.read<LoanProvider>().loadLoans(uid),
              context.read<TransactionProvider>().loadTransactions(uid),
              context.read<InvestmentProvider>().loadInvestments(uid),
            ]);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Month Selector Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevMonth,
                    tooltip: 'Previous Month',
                  ),
                  InkWell(
                    onTap: _pickMonthYear,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Text(
                            AppDateUtils.formatMonthYear(_selectedYear, _selectedMonth),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextMonth,
                    tooltip: 'Next Month',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Hero Net Cashflow Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSurplus
                      ? [const Color(0xFF312E81), const Color(0xFF4F46E5), const Color(0xFF0EA5E9)]
                      : [const Color(0xFF881337), const Color(0xFFBE123C), const Color(0xFFF43F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isSurplus ? const Color(0xFF4F46E5) : const Color(0xFFBE123C)).withAlpha(80),
                    blurRadius: 18,
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
                      Text(
                        'Net Cashflow • ',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSurplus ? '✓ Net Surplus' : '⚠ Net Deficit',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Inflow & Outflow columns
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 16),
                                  SizedBox(width: 4),
                                  Text('Total Inflow', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(totalMonthlyInflow),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 16),
                                  SizedBox(width: 4),
                                  Text('Total Outflow', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(totalMonthlyOutflow),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Ratio Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Inflow: %',
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Outflow: %',
                            style: const TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: inflowRatio,
                          backgroundColor: const Color(0xFFF87171).withAlpha(150),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Inflow Breakdown Card
            _buildSectionCard(
              context: context,
              isDark: isDark,
              title: 'Monthly Inflows (Receive)',
              subtitle: 'All expected & received incomes this month',
              totalAmount: totalMonthlyInflow,
              accentColor: const Color(0xFF10B981),
              icon: Icons.call_received_rounded,
              items: [
                _buildBreakdownRow(
                  title: 'Income & Credits',
                  subtitle: ' transaction',
                  amount: monthlyCredit,
                  color: const Color(0xFF10B981),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _buildBreakdownRow(
                  title: 'Investment Passive Returns',
                  subtitle: ' active portfolio',
                  amount: invMonthlyReturn,
                  color: const Color(0xFF6366F1),
                  icon: Icons.savings_rounded,
                  actionText: 'View Portfolio',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvestmentListScreen()),
                  ),
                ),
                _buildBreakdownRow(
                  title: 'Receivables Due This Month',
                  subtitle: ' person due',
                  amount: monthlyReceivables,
                  color: const Color(0xFF0EA5E9),
                  icon: Icons.people_rounded,
                  actionText: 'View Dues',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PeopleDuesScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Outflow Breakdown Card
            _buildSectionCard(
              context: context,
              isDark: isDark,
              title: 'Monthly Outflows (Pay)',
              subtitle: 'All expenses, EMIs & commitments this month',
              totalAmount: totalMonthlyOutflow,
              accentColor: const Color(0xFFF43F5E),
              icon: Icons.call_made_rounded,
              items: [
                _buildBreakdownRow(
                  title: 'Living Expenses & Debits',
                  subtitle: ' expense',
                  amount: monthlyDebit,
                  color: const Color(0xFFF43F5E),
                  icon: Icons.shopping_bag_rounded,
                ),
                _buildBreakdownRow(
                  title: 'Active Loan EMIs',
                  subtitle: ' active loan',
                  amount: loanMonthlyEmis,
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.account_balance_rounded,
                  actionText: 'View Loans',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoanListScreen()),
                  ),
                ),
                _buildBreakdownRow(
                  title: 'Payables Due This Month',
                  subtitle: ' person due',
                  amount: monthlyPayables,
                  color: const Color(0xFFF97316),
                  icon: Icons.people_outline_rounded,
                  actionText: 'View Dues',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PeopleDuesScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Itemized Transactions Header & Filter Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itemized Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  ' items',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _filterChip('All ()', 'ALL'),
                const SizedBox(width: 8),
                _filterChip('Inflows ()', 'INFLOW'),
                const SizedBox(width: 8),
                _filterChip('Outflows ()', 'OUTFLOW'),
              ],
            ),

            const SizedBox(height: 12),

            // List of items
            if (displayTxs.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 44, color: isDark ? Colors.white30 : Colors.black26),
                    const SizedBox(height: 12),
                    Text(
                      'No direct transactions logged for ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Transaction'),
                    ),
                  ],
                ),
              )
            else
              ...displayTxs.map((tx) => _buildTransactionCard(context, tx, isDark)),

            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_tx_cashflow',
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      onSelected: (_) => setState(() => _filterType = value),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required double totalAmount,
    required Color accentColor,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(totalAmount),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
    String? actionText,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
              if (actionText != null && onTap != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onTap,
                  child: Text(
                    actionText,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx, bool isDark) {
    final isInflow = tx.type == 'CREDIT' || tx.type == 'RECEIVABLE';
    final color = isInflow ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isInflow ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ' • ',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (tx.status == 'COMPLETED' || tx.status == 'PAID' || tx.status == 'RECEIVED'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: tx.status == 'COMPLETED' || tx.status == 'PAID' || tx.status == 'RECEIVED'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
