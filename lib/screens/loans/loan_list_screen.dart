import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/whatsapp_button.dart';
import '../trash/trash_screen.dart';
import 'add_loan_screen.dart';
import 'loan_details_screen.dart';

class LoanListScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const LoanListScreen({super.key, this.onOpenDrawer});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> with SingleTickerProviderStateMixin {
  late TabController _loanTabController;

  @override
  void initState() {
    super.initState();
    _loanTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _loanTabController.dispose();
    super.dispose();
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

    final activeLoansCount = loanProv.activeLoans.length;
    final completedLoansCount = loanProv.completedLoans.length;
    final totalTrashCount = loanProv.deletedLoans.length;

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
            const Text(
              'Personal Loans & EMIs',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              '$activeLoansCount Active • Total EMI: ${CurrencyFormatter.format(loanProv.totalMonthlyEmis)}/mo',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _loanTabController,
            indicatorColor: const Color(0xFF6366F1),
            labelColor: const Color(0xFF6366F1),
            tabs: [
              Tab(text: 'Active Loans ($activeLoansCount)'),
              Tab(text: 'Completed ($completedLoansCount)'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_loan',
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add New Loan', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLoanScreen()),
          );
        },
      ),
      body: TabBarView(
        controller: _loanTabController,
        children: [
          _buildLoanList(context, loanProv.activeLoans, isDark, isActive: true),
          _buildLoanList(context, loanProv.completedLoans, isDark, isActive: false),
        ],
      ),
    );
  }

  Widget _buildLoanList(BuildContext context, List<LoanModel> loans, bool isDark, {required bool isActive}) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.account_balance_outlined : Icons.check_circle_outline_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isActive ? 'No active loans found' : 'No completed loans yet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'Tap "+ Add New Loan" to track your EMIs' : 'Cleared loans will appear here',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: loans.length,
      itemBuilder: (ctx, i) {
        final loan = loans[i];
        final nextDue = loan.nextDueDate;
        final isDueSoon = nextDue.difference(DateTime.now()).inDays <= 3;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDueSoon
                  ? const Color(0xFFF59E0B).withAlpha(120)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isDueSoon ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Color(0xFF6366F1), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            Text(
                              loan.lenderName,
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
                            CurrencyFormatter.format(loan.emiAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const Text(
                            '/ month EMI',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (val) {
                          if (val == 'details') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoanDetailsScreen(loan: loan)),
                            );
                          } else if (val == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddLoanScreen(loanToEdit: loan)),
                            );
                          } else if (val == 'delete') {
                            _confirmDeleteLoan(context, loan);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Full Breakdown'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Loan Details'),
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
                  const SizedBox(height: 14),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: loan.progressPercentage,
                      minHeight: 7,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        loan.progressPercentage >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loan.paidEmis} / ${loan.totalEmis} EMIs Paid (${(loan.progressPercentage * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        'Balance: ${CurrencyFormatter.format(loan.remainingBalance)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF43F5E),
                        ),
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
                            Icon(Icons.calendar_today_outlined, size: 13, color: isDark ? Colors.white54 : Colors.black54),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Next Due: ${AppDateUtils.formatShort(nextDue)} (Day ${loan.dueDay})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isDueSoon ? FontWeight.w700 : FontWeight.normal,
                                  color: isDueSoon ? const Color(0xFFF59E0B) : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WhatsAppButton(
                            personName: 'Self',
                            phoneNumber: '9010067464',
                            amount: loan.emiAmount,
                            dueDate: nextDue,
                            note: 'Monthly EMI for ${loan.title}',
                          ),
                          if (isActive && loan.remainingEmis > 0) ...[
                            const SizedBox(width: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 30),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                await context.read<LoanProvider>().payEmi(loan: loan);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('EMI #${loan.paidEmis + 1} recorded as paid for ${loan.title}!'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Pay EMI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
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
}
