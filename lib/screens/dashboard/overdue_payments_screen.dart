import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/whatsapp_button.dart';
import '../loans/loan_list_screen.dart';
import '../people/add_due_screen.dart';

/// Screen displaying all Overdue Payments & Loan EMIs
/// Provides complete interactive management: Status update, Full/Partial settlement, Rescheduling, and Editing details.
class OverduePaymentsScreen extends StatefulWidget {
  const OverduePaymentsScreen({super.key});

  @override
  State<OverduePaymentsScreen> createState() => _OverduePaymentsScreenState();
}

class _OverduePaymentsScreenState extends State<OverduePaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProv = context.watch<TransactionProvider>();
    final loanProv = context.watch<LoanProvider>();

    final overdueTxs = txProv.overdueTransactions;
    final overduePayables = overdueTxs.where((t) => t.type == 'PAYABLE').toList();
    final overdueReceivables = overdueTxs.where((t) => t.type == 'RECEIVABLE').toList();

    // Check loans with due days past in current month
    final now = DateTime.now();
    final overdueLoans = loanProv.activeLoans.where((loan) {
      final dueDateThisMonth = DateTime(now.year, now.month, loan.dueDay.clamp(1, 28));
      return now.isAfter(dueDateThisMonth) && loan.remainingEmis > 0;
    }).toList();

    final totalOverduePayablesAmount = overduePayables.fold(0.0, (s, t) => s + t.amount);
    final totalOverdueReceivablesAmount = overdueReceivables.fold(0.0, (s, t) => s + t.amount);
    final totalOverdueLoansAmount = overdueLoans.fold(0.0, (s, l) => s + l.emiAmount);
    final grandTotalOverdue = totalOverduePayablesAmount + totalOverdueReceivablesAmount + totalOverdueLoansAmount;
    final totalOverdueCount = overdueTxs.length + overdueLoans.length;

    final query = _searchController.text.trim().toLowerCase();

    List<TransactionModel> filterTxs(List<TransactionModel> list) {
      if (query.isEmpty) return list;
      return list.where((t) {
        final nameMatch = t.personName?.toLowerCase().contains(query) ?? false;
        final titleMatch = t.title.toLowerCase().contains(query);
        final notesMatch = t.notes?.toLowerCase().contains(query) ?? false;
        return nameMatch || titleMatch || notesMatch;
      }).toList();
    }

    List<LoanModel> filterLoans(List<LoanModel> list) {
      if (query.isEmpty) return list;
      return list.where((l) {
        final titleMatch = l.title.toLowerCase().contains(query);
        final lenderMatch = l.lenderName.toLowerCase().contains(query);
        return titleMatch || lenderMatch;
      }).toList();
    }

    final filteredAllTxs = filterTxs(overdueTxs);
    final filteredPayables = filterTxs(overduePayables);
    final filteredReceivables = filterTxs(overdueReceivables);
    final filteredLoans = filterLoans(overdueLoans);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Overdue Payments', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.debitRed,
          labelColor: AppTheme.debitRed,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'All Overdue ($totalOverdueCount)'),
            Tab(text: 'Payables (${overduePayables.length})'),
            Tab(text: 'Receivables (${overdueReceivables.length})'),
            Tab(text: 'Loan EMIs (${overdueLoans.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = context.read<AuthProvider>().currentUser?.id;
          if (uid != null) {
            await context.read<TransactionProvider>().loadTransactions(uid);
            if (context.mounted) {
              await context.read<LoanProvider>().loadLoans(uid);
            }
          }
        },
        child: Column(
          children: [
            // 1. Hero Overdue Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFE11D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'TOTAL OVERDUE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalOverdueCount Pending',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(grandTotalOverdue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildMiniBadge('I Owe: ${CurrencyFormatter.format(totalOverduePayablesAmount)}'),
                      _buildMiniBadge('To Receive: ${CurrencyFormatter.format(totalOverdueReceivablesAmount)}'),
                      if (totalOverdueLoansAmount > 0)
                        _buildMiniBadge('EMIs: ${CurrencyFormatter.format(totalOverdueLoansAmount)}'),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search overdue payment or person...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 3. Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: All Overdue
                  _buildCombinedOverdueList(context, isDark, filteredAllTxs, filteredLoans),

                  // Tab 2: Payables (I Owe)
                  _buildTransactionOverdueList(context, isDark, filteredPayables, 'No overdue payables! You are clear.'),

                  // Tab 3: Receivables (To Receive)
                  _buildTransactionOverdueList(context, isDark, filteredReceivables, 'No overdue receivables! Great job.'),

                  // Tab 4: Loan EMIs
                  _buildLoanOverdueList(context, isDark, filteredLoans),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCombinedOverdueList(
    BuildContext context,
    bool isDark,
    List<TransactionModel> txs,
    List<LoanModel> loans,
  ) {
    if (txs.isEmpty && loans.isEmpty) {
      return _buildEmptyPlaceholder(isDark, 'Zero Overdue Payments 🎉', 'All your dues and loans are currently on track!');
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        if (txs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'OVERDUE DUES (${txs.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ...txs.map((tx) => _buildOverdueTransactionCard(context, isDark, tx)),
        ],
        if (loans.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'OVERDUE LOAN EMIS (${loans.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ...loans.map((loan) => _buildOverdueLoanCard(context, isDark, loan)),
        ],
      ],
    );
  }

  Widget _buildTransactionOverdueList(
    BuildContext context,
    bool isDark,
    List<TransactionModel> txs,
    String emptyMessage,
  ) {
    if (txs.isEmpty) {
      return _buildEmptyPlaceholder(isDark, 'All Clear!', emptyMessage);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: txs.length,
      itemBuilder: (ctx, i) => _buildOverdueTransactionCard(context, isDark, txs[i]),
    );
  }

  Widget _buildLoanOverdueList(
    BuildContext context,
    bool isDark,
    List<LoanModel> loans,
  ) {
    if (loans.isEmpty) {
      return _buildEmptyPlaceholder(isDark, 'No Overdue EMIs!', 'All active loan installments are up to date.');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: loans.length,
      itemBuilder: (ctx, i) => _buildOverdueLoanCard(context, isDark, loans[i]),
    );
  }

  Widget _buildEmptyPlaceholder(bool isDark, String title, String subtitle) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueTransactionCard(BuildContext context, bool isDark, TransactionModel tx) {
    final isReceivable = tx.type == 'RECEIVABLE';
    final daysOverdue = DateTime.now().difference(tx.dueDate).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFFF43F5E).withAlpha(isDark ? 90 : 60),
          width: 1.2,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        onTap: () => _showPaymentOptionsSheet(context, tx),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Type badge, Days overdue tag, Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isReceivable
                                ? const Color(0xFF10B981).withAlpha(25)
                                : const Color(0xFFF43F5E).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isReceivable ? 'TO RECEIVE' : 'I OWE (PAYABLE)',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withAlpha(isDark ? 40 : 20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 11, color: Color(0xFFF43F5E)),
                              const SizedBox(width: 3),
                              Text(
                                '$daysOverdue d overdue',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF43F5E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    CurrencyFormatter.format(tx.amount),
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Person and Title
              Text(
                tx.personName?.isNotEmpty == true ? tx.personName! : tx.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              if (tx.personName?.isNotEmpty == true && tx.title != tx.personName)
                Text(
                  tx.title,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom actions row: Due date, Call, WhatsApp, Settle
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Due: ${AppDateUtils.formatShort(tx.dueDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tx.phoneNumber?.isNotEmpty == true) ...[
                        IconButton(
                          icon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF3B82F6)),
                          tooltip: 'Call Person',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () => _makePhoneCall(tx.phoneNumber!),
                        ),
                        const SizedBox(width: 6),
                        WhatsAppButton(
                          personName: tx.personName ?? tx.title,
                          phoneNumber: tx.phoneNumber!,
                          amount: tx.amount,
                          dueDate: tx.dueDate,
                          note: isReceivable
                              ? 'Urgent Reminder: Payment of ${CurrencyFormatter.format(tx.amount)} was due on ${AppDateUtils.formatShort(tx.dueDate)}.'
                              : 'Regarding pending payment of ${CurrencyFormatter.format(tx.amount)} for ${tx.title}.',
                        ),
                        const SizedBox(width: 6),
                      ],
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 30),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showPaymentOptionsSheet(context, tx),
                        child: const Text('Manage / Settle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueLoanCard(BuildContext context, bool isDark, LoanModel loan) {
    final now = DateTime.now();
    final nextDue = DateTime(now.year, now.month, loan.dueDay.clamp(1, 28));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF8B5CF6).withAlpha(isDark ? 90 : 60),
          width: 1.2,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B5CF6), width: 0.8),
                  ),
                  child: const Text(
                    'LOAN EMI OVERDUE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6)),
                  ),
                ),
                const Spacer(),
                Text(
                  CurrencyFormatter.format(loan.emiAmount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(loan.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Lender: ${loan.lenderName}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Was Due: ${AppDateUtils.formatShort(nextDue)} (Day ${loan.dueDay})',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFF43F5E), fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 30),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await context.read<LoanProvider>().payEmi(loan: loan);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('EMI #${loan.paidEmis + 1} marked as paid for ${loan.title}!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  child: const Text('Pay EMI Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoanListScreen()),
                    );
                  },
                  child: const Text('View Loan', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Interactive Payment Options Bottom Sheet ---
  void _showPaymentOptionsSheet(BuildContext context, TransactionModel tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReceivable = tx.type == 'RECEIVABLE';
    final completedLabel = isReceivable ? 'Mark as Received' : 'Mark as Paid';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Amount Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.personName?.isNotEmpty == true ? tx.personName! : tx.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${isReceivable ? "To Receive" : "I Owe"} • Due: ${AppDateUtils.formatShort(tx.dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(tx.amount),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),

              // Quick Action 1: Full Settlement (Mark as Paid/Received)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                ),
                title: Text(completedLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Record 100% full settlement for this due', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<TransactionProvider>().markAsCompleted(tx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${tx.title} marked as completed!'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),

              // Quick Action 2: Partial Payment
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                title: const Text('Record Partial Payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Deduct partial amount and update remaining balance', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPartialPaymentDialog(context, tx);
                },
              ),

              // Quick Action 3: Reschedule Due Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF3B82F6), size: 22),
                ),
                title: const Text('Reschedule Due Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Extend or update the payment target deadline', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickNewDueDate(context, tx);
                },
              ),

              // Quick Action 4: Edit Full Details
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 22),
                ),
                title: const Text('Edit Due Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Modify amount, person, phone, notes, or category', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddDueScreen(dueToEdit: tx)),
                  );
                },
              ),

              // Quick Action 5: Move to Trash / Delete
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 22),
                ),
                title: const Text('Delete / Move to Trash', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFF43F5E))),
                subtitle: const Text('Remove this overdue entry from active ledger', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteDue(context, tx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Partial Payment Dialog ---
  void _showPartialPaymentDialog(BuildContext context, TransactionModel tx) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Partial Settlement (${CurrencyFormatter.format(tx.amount)})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the partial amount cleared:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount Cleared',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'e.g., GPay transaction reference',
                border: OutlineInputBorder(),
              ),
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
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final val = double.tryParse(amountController.text.trim());
              if (val == null || val <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount.')),
                );
                return;
              }
              Navigator.pop(ctx);
              await context.read<TransactionProvider>().recordPartialPayment(
                transaction: tx,
                paidAmount: val,
                note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Recorded partial payment of ${CurrencyFormatter.format(val)}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  // --- Reschedule Due Date Picker ---
  Future<void> _pickNewDueDate(BuildContext context, TransactionModel tx) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null && context.mounted) {
      final updatedTx = tx.copyWith(dueDate: pickedDate);
      await context.read<TransactionProvider>().updateTransaction(updatedTx);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Due date rescheduled to ${AppDateUtils.formatShort(pickedDate)}!'),
            backgroundColor: const Color(0xFF3B82F6),
          ),
        );
      }
    }
  }

  // --- Confirm Delete ---
  void _confirmDeleteDue(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('Are you sure you want to delete overdue entry "${tx.title}"? You can restore it from Trash anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TransactionProvider>().softDeleteTransaction(tx.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${tx.title} moved to trash.'),
                    backgroundColor: const Color(0xFFF43F5E),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
