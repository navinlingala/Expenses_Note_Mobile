import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/whatsapp_button.dart';
import '../people/add_due_screen.dart';
import '../trash/trash_screen.dart';
import 'add_loan_screen.dart';
import 'loan_details_screen.dart';

class LoanListScreen extends StatefulWidget {
  final int initialSection; // 0 for Loans, 1 for Dues
  const LoanListScreen({super.key, this.initialSection = 0});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> with TickerProviderStateMixin {
  late int _currentSection; // 0 = Loans, 1 = Dues
  late TabController _loanTabController;
  late TabController _duesTabController;
  String _duesStatusFilter = 'PENDING'; // PENDING or ALL

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    _loanTabController = TabController(length: 2, vsync: this);
    _duesTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _loanTabController.dispose();
    _duesTabController.dispose();
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
          const SnackBar(content: Text('Could not launch phone call.')),
        );
      }
    }
  }

  void _confirmDeleteLoan(BuildContext context, LoanModel loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('Move "${loan.title}" to Trash? You can restore it later or delete it permanently from Trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<LoanProvider>().softDeleteLoan(loan.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${loan.title}" moved to Trash.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.amber,
                      onPressed: () {
                        context.read<LoanProvider>().restoreLoan(loan.id);
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loanProv = context.watch<LoanProvider>();
    final txProv = context.watch<TransactionProvider>();

    final activeLoansCount = loanProv.activeLoans.length;
    final pendingDuesCount = txProv.pendingReceivables.length + txProv.pendingPayables.length;
    final totalTrashCount = loanProv.deletedLoans.length + txProv.deletedTransactions.length;

    // Dues lists
    final receivables = _duesStatusFilter == 'PENDING' ? txProv.pendingReceivables : txProv.receivables;
    final payables = _duesStatusFilter == 'PENDING' ? txProv.pendingPayables : txProv.payables;
    final totalReceive = txProv.totalToReceive;
    final totalPay = txProv.totalToPay;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentSection == 0 ? 'Loans & EMIs' : 'People Dues',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              _currentSection == 0
                  ? '$activeLoansCount Active • ${CurrencyFormatter.format(loanProv.totalMonthlyEmis)}/mo'
                  : 'Track Who Owes Me & Whom I Owe',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // PROFESSIONAL TOP BUTTON TO SWITCH BETWEEN LOANS & DUES
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentSection == 0
                    ? const Color(0xFF10B981).withAlpha(30)
                    : const Color(0xFF6366F1).withAlpha(30),
                foregroundColor: _currentSection == 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6366F1),
                elevation: 0,
                side: BorderSide(
                  color: _currentSection == 0 ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  width: 1.3,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: Badge(
                isLabelVisible: _currentSection == 0 ? pendingDuesCount > 0 : activeLoansCount > 0,
                label: Text(_currentSection == 0 ? '$pendingDuesCount' : '$activeLoansCount'),
                child: Icon(
                  _currentSection == 0 ? Icons.people_alt_rounded : Icons.account_balance_rounded,
                  size: 16,
                ),
              ),
              label: Text(
                _currentSection == 0 ? 'Dues' : 'Loans',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              onPressed: () {
                setState(() {
                  _currentSection = _currentSection == 0 ? 1 : 0;
                });
              },
            ),
          ),

          // Trash Button
          IconButton(
            tooltip: 'View Trash',
            icon: Badge(
              isLabelVisible: totalTrashCount > 0,
              label: Text('$totalTrashCount'),
              child: const Icon(Icons.delete_outline_rounded),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),

          // Filter button for Dues
          if (_currentSection == 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list_rounded),
              onSelected: (val) => setState(() => _duesStatusFilter = val),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'PENDING', child: Text('Pending Only')),
                const PopupMenuItem(value: 'ALL', child: Text('All (Including Completed)')),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _currentSection == 0
              ? TabBar(
                  key: const ValueKey('loan_tabs'),
                  controller: _loanTabController,
                  indicatorColor: const Color(0xFF6366F1),
                  labelColor: const Color(0xFF6366F1),
                  tabs: [
                    Tab(text: 'Active Loans (${loanProv.activeLoans.length})'),
                    Tab(text: 'Completed (${loanProv.completedLoans.length})'),
                  ],
                )
              : TabBar(
                  key: const ValueKey('dues_tabs'),
                  controller: _duesTabController,
                  indicatorColor: const Color(0xFF10B981),
                  labelColor: const Color(0xFF10B981),
                  tabs: [
                    Tab(text: 'Who Owes Me (${CurrencyFormatter.format(totalReceive)})'),
                    Tab(text: 'Whom I Owe (${CurrencyFormatter.format(totalPay)})'),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: _currentSection == 0 ? 'fab_add_loan_unified' : 'fab_add_due_unified',
        backgroundColor: _currentSection == 0
            ? const Color(0xFF6366F1)
            : (_duesTabController.index == 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
        foregroundColor: Colors.white,
        onPressed: () {
          if (_currentSection == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen()));
          } else {
            final initialType = _duesTabController.index == 0 ? 'RECEIVABLE' : 'PAYABLE';
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddDueScreen(initialType: initialType)),
            );
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _currentSection == 0
              ? 'Add Loan'
              : (_duesTabController.index == 0 ? 'Add Receivable' : 'Add Payable'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _currentSection == 0
          ? TabBarView(
              controller: _loanTabController,
              children: [
                _buildLoanList(context, loanProv.activeLoans, isDark, true),
                _buildLoanList(context, loanProv.completedLoans, isDark, false),
              ],
            )
          : TabBarView(
              controller: _duesTabController,
              children: [
                _buildDuesList(context, receivables, isDark, true, txProv),
                _buildDuesList(context, payables, isDark, false, txProv),
              ],
            ),
    );
  }

  // --- LOANS LIST BUILDER ---
  Widget _buildLoanList(BuildContext context, List<LoanModel> loans, bool isDark, bool isActive) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey.withAlpha(120)),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active loans being tracked.' : 'No completed loans yet.',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (isActive)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen())),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add First Loan'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoanDetailsScreen(loan: loan)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
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
                      ),
                      Row(
                        children: [
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
                                'Due: ${loan.dueDay}th of month',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                            onSelected: (val) {
                              if (val == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddLoanScreen(loanToEdit: loan)),
                                );
                              } else if (val == 'delete') {
                                _confirmDeleteLoan(context, loan);
                              } else if (val == 'view') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => LoanDetailsScreen(loan: loan)),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('View Details')]),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6366F1)), SizedBox(width: 8), Text('Edit Loan')]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF43F5E)), SizedBox(width: 8), Text('Move to Trash', style: TextStyle(color: Color(0xFFF43F5E)))]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loan.progressPercentage,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loan.paidEmis} of ${loan.totalEmis} paid',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      Text(
                        'Remaining: ${CurrencyFormatter.format(loan.remainingBalance)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- DUES LIST BUILDER ---
  Widget _buildDuesList(
    BuildContext context,
    List<TransactionModel> items,
    bool isDark,
    bool isReceivable,
    TransactionProvider txProv,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded,
              size: 64,
              color: Colors.grey.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              isReceivable ? 'No pending amounts to receive.' : 'No pending amounts to pay.',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddDueScreen(initialType: isReceivable ? 'RECEIVABLE' : 'PAYABLE')),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(isReceivable ? 'Add Receivable' : 'Add Payable'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCompleted = item.status == 'RECEIVED' || item.status == 'PAID';

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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: (isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withAlpha(30),
                          child: Text(
                            item.personName?.isNotEmpty == true ? item.personName![0].toUpperCase() : 'P',
                            style: TextStyle(
                              color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.personName ?? 'Unknown Person',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              item.title,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(item.amount),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isCompleted
                                    ? const Color(0xFF10B981)
                                    : item.isOverdue
                                        ? const Color(0xFFF43F5E)
                                        : const Color(0xFFF59E0B))
                                .withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCompleted
                                ? (isReceivable ? 'RECEIVED' : 'PAID')
                                : item.isOverdue
                                    ? 'OVERDUE'
                                    : AppDateUtils.getRelativeDueDate(item.dueDate),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : item.isOverdue
                                      ? const Color(0xFFF43F5E)
                                      : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_outlined, size: 13, color: isDark ? Colors.white54 : Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.formatShort(item.dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.phoneNumber?.isNotEmpty == true) ...[
                            InkWell(
                              onTap: () => _makePhoneCall(item.phoneNumber!),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF6366F1)),
                              ),
                            ),
                            if (isReceivable)
                              WhatsAppButton(
                                personName: item.personName ?? 'Friend',
                                phoneNumber: item.phoneNumber!,
                                amount: item.amount,
                                dueDate: item.dueDate,
                                note: item.notes,
                                isCompact: true,
                              ),
                          ],
                          if (!isCompleted)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 13),
                              label: Text(isReceivable ? 'Received' : 'Paid'),
                              onPressed: () => txProv.markAsCompleted(item),
                            ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                            onSelected: (val) {
                              if (val == 'partial_pay') {
                                _showPartialPaymentDialog(context, item, isReceivable);
                              } else if (val == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddDueScreen(dueToEdit: item, initialType: item.type)),
                                );
                              } else if (val == 'delete') {
                                txProv.softDeleteTransaction(item.id);
                              }
                            },
                            itemBuilder: (_) => [
                              if (!isCompleted)
                                const PopupMenuItem(
                                  value: 'partial_pay',
                                  child: Row(
                                    children: [
                                      Icon(Icons.payments_outlined, size: 18, color: Color(0xFF10B981)),
                                      SizedBox(width: 8),
                                      Text('Record Payment'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6366F1)),
                                    SizedBox(width: 8),
                                    Text('Edit Due & Contact'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF43F5E)),
                                    SizedBox(width: 8),
                                    Text('Move to Trash', style: TextStyle(color: Color(0xFFF43F5E))),
                                  ],
                                ),
                              ),
                            ],
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
      },
    );
  }

  void _showPartialPaymentDialog(BuildContext context, TransactionModel item, bool isReceivable) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final payingAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
          final remaining = (item.amount - payingAmount).clamp(0.0, double.infinity);
          final isFull = payingAmount >= item.amount && item.amount > 0;

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isReceivable ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isReceivable
                        ? 'Record Payment from ${item.personName ?? item.title}'
                        : 'Record Payment to ${item.personName ?? item.title}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Due Outstanding: ${CurrencyFormatter.format(item.amount)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),

                  // Quick percentage chips
                  const Text('Quick Select Amount:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('25%'),
                        onPressed: () {
                          final val = (item.amount * 0.25).round();
                          amountController.text = val.toString();
                          setDialogState(() {});
                        },
                      ),
                      ActionChip(
                        label: const Text('50%'),
                        onPressed: () {
                          final val = (item.amount * 0.50).round();
                          amountController.text = val.toString();
                          setDialogState(() {});
                        },
                      ),
                      ActionChip(
                        label: const Text('75%'),
                        onPressed: () {
                          final val = (item.amount * 0.75).round();
                          amountController.text = val.toString();
                          setDialogState(() {});
                        },
                      ),
                      ActionChip(
                        label: const Text('Full (100%)'),
                        backgroundColor: const Color(0xFF10B981).withAlpha(40),
                        onPressed: () {
                          final val = item.amount.toInt();
                          amountController.text = val.toString();
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: isReceivable ? 'Amount Received (₹)' : 'Amount Paid (₹)',
                      hintText: 'e.g. 500',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Note / Mode',
                      hintText: 'e.g. Paid via GPay / UPI',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Real-time calculation card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155).withAlpha(100) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Remaining Balance:', style: TextStyle(fontSize: 12)),
                            Text(
                              isFull ? '₹0 (Fully Cleared!)' : CurrencyFormatter.format(remaining),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isFull ? const Color(0xFF10B981) : const Color(0xFF6366F1),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid payment amount')),
                    );
                    return;
                  }

                  await context.read<TransactionProvider>().recordPartialPayment(
                    transaction: item,
                    paidAmount: amt,
                    note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          amt >= item.amount
                              ? 'Payment of ${CurrencyFormatter.format(amt)} recorded! Due marked as fully settled.'
                              : 'Payment of ${CurrencyFormatter.format(amt)} recorded! Remaining balance: ${CurrencyFormatter.format(remaining)}',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                child: const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );
  }
}
