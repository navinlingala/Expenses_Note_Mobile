import '../../core/services/whatsapp_service.dart';
import 'add_loan_screen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/loan_model.dart';
import '../../models/payment_history_model.dart';
import '../../providers/loan_provider.dart';

class LoanDetailsScreen extends StatefulWidget {
  final LoanModel loan;
  const LoanDetailsScreen({super.key, required this.loan});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  late Future<List<PaymentHistoryModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = context.read<LoanProvider>().getLoanPaymentHistory(widget.loan.id, widget.loan.userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loanProv = context.watch<LoanProvider>();
    final currentLoan = loanProv.loans.firstWhere(
      (l) => l.id == widget.loan.id,
      orElse: () => widget.loan,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLoan.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Loan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddLoanScreen(loanToEdit: currentLoan)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Move to Trash',
            onPressed: () => _confirmDelete(context, currentLoan.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amortization & Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentLoan.lenderName,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentLoan.status == 'ACTIVE'
                            ? const Color(0xFF10B981).withAlpha(30)
                            : const Color(0xFF6366F1).withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentLoan.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: currentLoan.status == 'ACTIVE'
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.format(currentLoan.totalPrincipal),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const Text('Total Loan Principal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: currentLoan.progressPercentage,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid: ${currentLoan.paidEmis} EMIs\n(${CurrencyFormatter.format(currentLoan.totalPaidAmount)})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Remaining: ${currentLoan.remainingEmis} EMIs\n(${CurrencyFormatter.format(currentLoan.remainingBalance)})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                const Divider(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBlock('Monthly EMI', CurrencyFormatter.format(currentLoan.emiAmount)),
                    _infoBlock('Due Day', '${currentLoan.dueDay}th of month'),
                    _infoBlock('Next Due', AppDateUtils.formatShort(currentLoan.nextDueDate)),
                  ],
                ),

                if (currentLoan.status == 'ACTIVE') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<LoanProvider>().payEmi(loan: currentLoan);
                        setState(() => _loadHistory());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('EMI #${currentLoan.paidEmis + 1} recorded as paid! ✅'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Mark Next EMI as Paid'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('Send EMI Alert to My WhatsApp (+91 9010067464)'),
                      onPressed: () async {
                        final msg = WhatsAppService.instance.generateLoanEmiReminder(
                          loanTitle: currentLoan.title,
                          lenderName: currentLoan.lenderName,
                          emiAmount: currentLoan.emiAmount,
                          dueDay: currentLoan.dueDay,
                          paidEmis: currentLoan.paidEmis,
                          totalEmis: currentLoan.totalEmis,
                          remainingBalance: currentLoan.remainingBalance,
                          nextDueDate: currentLoan.nextDueDate,
                        );
                        await WhatsAppService.instance.sendToUserWhatsApp(message: msg);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Payment & EMI History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<PaymentHistoryModel>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('No payments recorded yet.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (context, idx) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                    title: Text(item.note ?? 'EMI Payment', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(AppDateUtils.formatShort(item.paidDate)),
                    trailing: Text(
                      CurrencyFormatter.format(item.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String loanId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: const Text('Move this loan to Trash? You can restore it anytime or delete it permanently from Trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              await context.read<LoanProvider>().softDeleteLoan(loanId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Loan moved to Trash.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.amber,
                      onPressed: () {
                        context.read<LoanProvider>().restoreLoan(loanId);
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

