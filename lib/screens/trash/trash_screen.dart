import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';
import '../../models/investment_model.dart';
import '../../providers/investment_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _emptyTrash(BuildContext context, List<LoanModel> deletedLoans, List<TransactionModel> deletedTxs, List<InvestmentModel> deletedInvestments) {
    if (deletedLoans.isEmpty && deletedTxs.isEmpty && deletedInvestments.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E)),
            SizedBox(width: 8),
            Text('Empty Trash?'),
          ],
        ),
        content: Text(
          'This will PERMANENTLY delete ${deletedLoans.length + deletedTxs.length} items from cloud and local storage.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              final loanProv = context.read<LoanProvider>();
              final txProv = context.read<TransactionProvider>();

              for (final l in List.from(deletedLoans)) {
                await loanProv.deleteLoanPermanently(l.id);
              }
              for (final t in List.from(deletedTxs)) {
                await txProv.deleteTransactionPermanently(t.id);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trash emptied. All items deleted permanently.'),
                    backgroundColor: Color(0xFFF43F5E),
                  ),
                );
              }
            },
            child: const Text('Empty All'),
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
    final invProv = context.watch<InvestmentProvider>();

    final deletedLoans = loanProv.deletedLoans;
    final allDeletedTxs = txProv.deletedTransactions;

    final deletedCreditsDebits = allDeletedTxs
        .where((t) => t.type == 'CREDIT' || t.type == 'DEBIT')
        .toList();

    final deletedDues = allDeletedTxs
        .where((t) => t.type == 'RECEIVABLE' || t.type == 'PAYABLE')
        .toList();

    final deletedInvestments = invProv.deletedInvestments;
    final totalDeletedCount = deletedLoans.length + allDeletedTxs.length + deletedInvestments.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash & Deleted Items'),
        actions: [
          if (totalDeletedCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFF43F5E), size: 18),
              label: const Text('Empty Trash', style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
              onPressed: () => _emptyTrash(context, deletedLoans, allDeletedTxs, deletedInvestments),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          tabs: [
            Tab(text: 'All ($totalDeletedCount)'),
            Tab(text: 'Loans (${deletedLoans.length})'),
            Tab(text: 'Transactions (${deletedCreditsDebits.length})'),
            Tab(text: 'People Dues (${deletedDues.length})'),
            Tab(text: 'Investments (${deletedInvestments.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Tab
          _buildAllList(context, deletedLoans, allDeletedTxs, isDark),
          // Loans Tab
          _buildLoansList(context, deletedLoans, isDark),
          // Transactions Tab
          _buildTransactionsList(context, deletedCreditsDebits, isDark),
          // People Dues Tab
          _buildTransactionsList(context, deletedDues, isDark),
          // Investments Tab
          _buildInvestmentsList(context, deletedInvestments, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, size: 68, color: Colors.grey.withAlpha(120)),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(fontSize: 15, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllList(BuildContext context, List<LoanModel> loans, List<TransactionModel> txs, bool isDark) {
    if (loans.isEmpty && txs.isEmpty) {
      return _buildEmptyState('Trash is empty.\nDeleted loans and transactions will appear here.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (loans.isNotEmpty) ...[
          const Text('Deleted Loans', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ...loans.map((l) => _buildLoanCard(context, l, isDark)),
          const SizedBox(height: 16),
        ],
        if (txs.isNotEmpty) ...[
          const Text('Deleted Transactions & Dues', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ...txs.map((t) => _buildTransactionCard(context, t, isDark)),
        ],
      ],
    );
  }

  Widget _buildLoansList(BuildContext context, List<LoanModel> loans, bool isDark) {
    if (loans.isEmpty) {
      return _buildEmptyState('No deleted loans in trash.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, idx) => _buildLoanCard(context, loans[idx], isDark),
    );
  }

  Widget _buildTransactionsList(BuildContext context, List<TransactionModel> txs, bool isDark) {
    if (txs.isEmpty) {
      return _buildEmptyState('No items in this category.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: txs.length,
      itemBuilder: (context, idx) => _buildTransactionCard(context, txs[idx], isDark),
    );
  }

  Widget _buildLoanCard(BuildContext context, LoanModel loan, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LOAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(loan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(
                  CurrencyFormatter.format(loan.totalPrincipal),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Lender: ${loan.lenderName} | EMI: ${CurrencyFormatter.format(loan.emiAmount)}/mo (${loan.remainingEmis} of ${loan.totalEmis} remaining)',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore_rounded, size: 16, color: Color(0xFF10B981)),
                  label: const Text('Restore', style: TextStyle(color: Color(0xFF10B981))),
                  onPressed: () async {
                    await context.read<LoanProvider>().restoreLoan(loan.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${loan.title}" restored to active loans!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Delete Permanently'),
                  onPressed: () => _confirmPermanentLoanDelete(context, loan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx, bool isDark) {
    Color badgeColor = const Color(0xFF0EA5E9);
    if (tx.type == 'CREDIT' || tx.type == 'RECEIVABLE') {
      badgeColor = const Color(0xFF10B981);
    } else if (tx.type == 'DEBIT' || tx.type == 'PAYABLE') {
      badgeColor = const Color(0xFFF43F5E);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tx.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text(
                  CurrencyFormatter.format(tx.amount),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: badgeColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${tx.personName != null ? "Person: ${tx.personName} | " : ""}${tx.category != null ? "Category: ${tx.category} | " : ""}Due: ${AppDateUtils.formatShort(tx.dueDate)}',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore_rounded, size: 16, color: Color(0xFF10B981)),
                  label: const Text('Restore', style: TextStyle(color: Color(0xFF10B981))),
                  onPressed: () async {
                    await context.read<TransactionProvider>().restoreTransaction(tx.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${tx.title}" restored!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Delete Permanently'),
                  onPressed: () => _confirmPermanentTransactionDelete(context, tx),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPermanentLoanDelete(BuildContext context, LoanModel loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E)),
            SizedBox(width: 8),
            Text('Delete Permanently?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${loan.title}"?\n\nThis will permanently erase all associated records from both cloud and local databases.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<LoanProvider>().deleteLoanPermanently(loan.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${loan.title}" permanently deleted.'),
                    backgroundColor: const Color(0xFFF43F5E),
                  ),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentTransactionDelete(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E)),
            SizedBox(width: 8),
            Text('Delete Permanently?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${tx.title}" (${CurrencyFormatter.format(tx.amount)})?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TransactionProvider>().deleteTransactionPermanently(tx.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${tx.title}" permanently deleted.'),
                    backgroundColor: const Color(0xFFF43F5E),
                  ),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList(BuildContext context, List<InvestmentModel> invs, bool isDark) {
    if (invs.isEmpty) {
      return _buildEmptyState('No investments in the Recycle Bin.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invs.length,
      itemBuilder: (context, index) => _buildInvestmentCard(context, invs[index], isDark),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, InvestmentModel inv, bool isDark) {
    final invProv = context.read<InvestmentProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF6366F1).withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.savings_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${inv.categoryDisplayName} • Invested ${CurrencyFormatter.format(inv.investedAmount)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(inv.currentValue),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                  onPressed: () async {
                    await invProv.restoreInvestment(inv.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${inv.title}" restored to portfolio.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                  label: const Text('Restore'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF43F5E),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await invProv.deleteInvestmentPermanently(inv.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${inv.title}" permanently deleted.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Delete Permanently'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
