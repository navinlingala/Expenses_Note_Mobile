import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/investment_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/whatsapp_button.dart';
import '../investments/investment_detail_screen.dart';
import '../people/add_due_screen.dart';

class ReceivablesDetailScreen extends StatefulWidget {
  const ReceivablesDetailScreen({super.key});

  @override
  State<ReceivablesDetailScreen> createState() => _ReceivablesDetailScreenState();
}

class _ReceivablesDetailScreenState extends State<ReceivablesDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'PENDING'; // PENDING, ALL, OVERDUE
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          const SnackBar(content: Text('Could not launch phone call.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProv = context.watch<TransactionProvider>();
    final invProv = context.watch<InvestmentProvider>();

    final allReceivables = txProv.receivables;
    final pendingReceivables = txProv.pendingReceivables;
    final totalPeopleReceive = txProv.totalToReceive;
    final invMonthlyReturn = invProv.totalExpectedMonthlyReturn;
    final grandTotalReceive = totalPeopleReceive + invMonthlyReturn;

    // Filter people dues
    List<TransactionModel> filteredDues;
    if (_statusFilter == 'PENDING') {
      filteredDues = pendingReceivables;
    } else if (_statusFilter == 'OVERDUE') {
      filteredDues = allReceivables.where((t) => t.isOverdue && t.status == 'PENDING').toList();
    } else {
      filteredDues = allReceivables;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredDues = filteredDues.where((t) {
        final nameMatch = t.personName?.toLowerCase().contains(query) ?? false;
        final titleMatch = t.title.toLowerCase().contains(query);
        return nameMatch || titleMatch;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivables & Inflows', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          tabs: [
            Tab(
              icon: const Icon(Icons.people_rounded, size: 18),
              text: 'People Dues ()',
            ),
            Tab(
              icon: const Icon(Icons.savings_rounded, size: 18),
              text: 'Investment Inflows ()',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Grand Total Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL MONEY TO RECEIVE',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(grandTotalReceive),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _submetricChip('People Dues: '),
                    const SizedBox(width: 8),
                    _submetricChip('Invest Return: +/mo'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: People Dues
                RefreshIndicator(
                  onRefresh: () async {
                    final uid = context.read<AuthProvider>().currentUser?.id;
                    if (uid != null) {
                      await context.read<TransactionProvider>().loadTransactions(uid);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Search & Filter
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search by person or title...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.filter_list_rounded),
                            onSelected: (val) => setState(() => _statusFilter = val),
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'PENDING', child: Text('Pending Only')),
                              const PopupMenuItem(value: 'OVERDUE', child: Text('Overdue Only')),
                              const PopupMenuItem(value: 'ALL', child: Text('All (Including Received)')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (filteredDues.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                              const SizedBox(height: 12),
                              const Text(
                                'No pending receivables found!',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap the button below whenever someone borrows money or owes you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredDues.map((due) => _buildDueCard(context, due, isDark, txProv)),
                    ],
                  ),
                ),

                // Tab 2: Investment Inflows
                RefreshIndicator(
                  onRefresh: () async {
                    final uid = context.read<AuthProvider>().currentUser?.id;
                    if (uid != null) {
                      await context.read<InvestmentProvider>().loadInvestments(uid);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (invProv.investments.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.savings_outlined, size: 48, color: Color(0xFF6366F1)),
                              const SizedBox(height: 12),
                              const Text(
                                'No active investments generating returns yet.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      else
                        ...invProv.investments.map((inv) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
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
                                            color: const Color(0xFF6366F1).withAlpha(30),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.trending_up_rounded, color: Color(0xFF6366F1), size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(inv.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            Text(inv.category, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withAlpha(30),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '+ / mo',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
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
                                        const Text('Capital Invested', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text(CurrencyFormatter.format(inv.investedAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Interest / Return Rate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text('% p.a.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1))),
                                      ],
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => InvestmentDetailScreen(investmentId: inv.id)),
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                      label: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_due_rec',
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Due (Owed to Me)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddDueScreen()),
        ),
      ),
    );
  }

  Widget _submetricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDueCard(BuildContext context, TransactionModel due, bool isDark, TransactionProvider txProv) {
    final isCompleted = due.status == 'RECEIVED' || due.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: due.isOverdue && !isCompleted
              ? const Color(0xFFF43F5E).withAlpha(100)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF10B981).withAlpha(30),
                    child: Text(
                      due.personName?.isNotEmpty == true ? due.personName![0].toUpperCase() : 'P',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        due.personName ?? 'Unknown Person',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        due.title,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(due.amount),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isCompleted
                              ? const Color(0xFF10B981)
                              : due.isOverdue
                                  ? const Color(0xFFF43F5E)
                                  : const Color(0xFFF59E0B))
                          .withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted
                          ? 'RECEIVED'
                          : due.isOverdue
                              ? 'OVERDUE'
                              : AppDateUtils.getRelativeDueDate(due.dueDate),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : due.isOverdue
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

          // Action Buttons: WhatsApp, Call, Mark Received
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
                    AppDateUtils.formatShort(due.dueDate),
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
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
                    if (due.phoneNumber?.isNotEmpty == true) ...[
                      InkWell(
                        onTap: () => _makePhoneCall(due.phoneNumber!),
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
                      WhatsAppButton(
                        personName: due.personName ?? 'Friend',
                        phoneNumber: due.phoneNumber!,
                        amount: due.amount,
                        dueDate: due.dueDate,
                        note: due.notes,
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
                        label: const Text('Received'),
                        onPressed: () => txProv.markAsCompleted(due),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
