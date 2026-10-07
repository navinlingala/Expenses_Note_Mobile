import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/whatsapp_button.dart';
import '../people/add_due_screen.dart';
import '../trash/trash_screen.dart';

class DuesScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const DuesScreen({super.key, this.onOpenDrawer});

  @override
  State<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends State<DuesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'PENDING';

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

  void _confirmDeleteDue(BuildContext context, TransactionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move Due to Trash?'),
        content: Text('Move "${item.title}" to Trash? You can restore it later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TransactionProvider>().softDeleteTransaction(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${item.title}" moved to Trash.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.amber,
                      onPressed: () {
                        context.read<TransactionProvider>().restoreTransaction(item.id);
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

  void _showPartialPaymentDialog(BuildContext context, TransactionModel item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.type == 'RECEIVABLE' ? 'Record Received Payment' : 'Record Paid Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remaining Balance: ${CurrencyFormatter.format(item.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount Paid (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              final paidAmount = double.tryParse(controller.text.trim());
              if (paidAmount == null || paidAmount <= 0) return;
              Navigator.pop(ctx);
              await context.read<TransactionProvider>().recordPartialPayment(
                    transaction: item,
                    paidAmount: paidAmount,
                  );
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
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
        leading: IconButton(
          tooltip: 'Open Menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            if (widget.onOpenDrawer != null) {
              widget.onOpenDrawer!();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('People Dues & Debts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(
              'To Receive: ${CurrencyFormatter.format(totalReceive)} • To Pay: ${CurrencyFormatter.format(totalPay)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter Status',
            onSelected: (val) => setState(() => _statusFilter = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'PENDING', child: Text('Pending Only')),
              const PopupMenuItem(value: 'ALL', child: Text('All (Including Settled)')),
            ],
          ),
          IconButton(
            tooltip: 'View Trash',
            icon: Badge(
              isLabelVisible: txProv.deletedTransactions.isNotEmpty,
              label: Text('${txProv.deletedTransactions.length}'),
              child: const Icon(Icons.delete_outline_rounded),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          tabs: [
            Tab(text: 'Who Owes Me (${receivables.length})'),
            Tab(text: 'Whom I Owe (${payables.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDuesList(receivables, isReceivable: true),
          _buildDuesList(payables, isReceivable: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dues',
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Due / Debt', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDueScreen(initialType: _tabController.index == 0 ? 'RECEIVABLE' : 'PAYABLE'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDuesList(List<TransactionModel> list, {required bool isReceivable}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded,
              size: 54,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isReceivable ? 'No dues to receive!' : 'No dues to pay!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              isReceivable ? 'Everyone has settled with you.' : 'You have no outstanding debts.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return _buildDueCard(item, isReceivable: isReceivable);
      },
    );
  }

  Widget _buildDueCard(TransactionModel item, {required bool isReceivable}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = item.isOverdue;
    final isPending = item.status == 'PENDING';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue
              ? const Color(0xFFF43F5E).withAlpha(100)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withAlpha(30),
                  child: Icon(
                    isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded,
                    color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.personName?.isNotEmpty == true ? item.personName! : item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPending ? (isOverdue ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B)) : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddDueScreen(dueToEdit: item)),
                      );
                    } else if (val == 'delete') {
                      _confirmDeleteDue(context, item);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Due / Person Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFF43F5E)),
                          SizedBox(width: 8),
                          Text('Move to Trash', style: TextStyle(color: Color(0xFFF43F5E))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Due: ${AppDateUtils.formatShort(item.dueDate)} (${AppDateUtils.getRelativeDueDate(item.dueDate)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.phoneNumber?.isNotEmpty == true) ...[
                      IconButton(
                        icon: const Icon(Icons.phone_outlined, size: 17, color: Color(0xFF3B82F6)),
                        tooltip: 'Call Person',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => _makePhoneCall(item.phoneNumber!),
                      ),
                      const SizedBox(width: 4),
                      WhatsAppButton(
                        personName: item.personName ?? item.title,
                        phoneNumber: item.phoneNumber!,
                        amount: item.amount,
                        dueDate: item.dueDate,
                        note: isReceivable
                            ? 'Reminder for pending payment of ${CurrencyFormatter.format(item.amount)}'
                            : 'Regarding payable amount for ${item.title}',
                      ),
                    ],
                    if (isPending) ...[
                      const SizedBox(width: 6),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                        label: const Text('Pay / Settle', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _showPartialPaymentDialog(context, item),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
