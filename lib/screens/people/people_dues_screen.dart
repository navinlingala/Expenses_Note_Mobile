import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/whatsapp_button.dart';
import 'add_due_screen.dart';
import '../trash/trash_screen.dart';

class PeopleDuesScreen extends StatefulWidget {
  const PeopleDuesScreen({super.key});

  @override
  State<PeopleDuesScreen> createState() => _PeopleDuesScreenState();
}

class _PeopleDuesScreenState extends State<PeopleDuesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'PENDING'; // PENDING or ALL

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProv = context.watch<TransactionProvider>();

    final receivables = _statusFilter == 'PENDING' ? txProv.pendingReceivables : txProv.receivables;
    final payables = _statusFilter == 'PENDING' ? txProv.pendingPayables : txProv.payables;

    final totalReceive = txProv.totalToReceive;
    final totalPay = txProv.totalToPay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('People Dues Tracker'),
        actions: [
          IconButton(
            tooltip: 'View Trash',
            icon: Badge(
              isLabelVisible: txProv.deletedTransactions.isNotEmpty,
              label: Text(''),
              child: const Icon(Icons.delete_outline_rounded),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (val) => setState(() => _statusFilter = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'PENDING', child: Text('Pending Only')),
              const PopupMenuItem(value: 'ALL', child: Text('All (Including Completed)')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          tabs: [
            Tab(text: 'Who Owes Me (${CurrencyFormatter.format(totalReceive)})'),
            Tab(text: 'Whom I Owe (${CurrencyFormatter.format(totalPay)})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_due',
        backgroundColor: _tabController.index == 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
        foregroundColor: Colors.white,
        onPressed: () {
          final initialType = _tabController.index == 0 ? 'RECEIVABLE' : 'PAYABLE';
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddDueScreen(initialType: initialType)),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'Add Receivable' : 'Add Payable'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Who owes me
          _buildDuesList(context, receivables, isDark, true),
          // Whom I owe
          _buildDuesList(context, payables, isDark, false),
        ],
      ),
    );
  }

  Widget _buildDuesList(BuildContext context, List<dynamic> items, bool isDark, bool isReceivable) {
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
          ],
        ),
      );
    }

    final color = isReceivable ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

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
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withAlpha(25),
                      foregroundColor: color,
                      child: Text(
                        (item.personName ?? item.title).substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.personName ?? item.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                            Text(
                              item.phoneNumber!,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.notes!,
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            isCompleted
                                ? 'Status: ${item.status} ✅'
                                : AppDateUtils.getRelativeDueDate(item.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : (item.isOverdue ? const Color(0xFFF43F5E) : (isDark ? Colors.white70 : Colors.black87)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(item.amount),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                          onPressed: () => _confirmDelete(context, item.id),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!isCompleted) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isReceivable && item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                        WhatsAppButton(
                          personName: item.personName ?? item.title,
                          phoneNumber: item.phoneNumber!,
                          amount: item.amount,
                          dueDate: item.dueDate,
                          note: item.notes,
                        )
                      else
                        const SizedBox(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          context.read<TransactionProvider>().markAsCompleted(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isReceivable
                                    ? 'Marked as Received from ${item.personName ?? item.title} ✅'
                                    : 'Marked as Paid to ${item.personName ?? item.title} ✅',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                        child: Text(isReceivable ? 'Mark Received' : 'Mark Paid'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: const Text('Move this due record to Trash? You can restore it anytime or permanently delete it from Trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TransactionProvider>().softDeleteTransaction(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Entry moved to Trash.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.amber,
                      onPressed: () {
                        context.read<TransactionProvider>().restoreTransaction(id);
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
}
