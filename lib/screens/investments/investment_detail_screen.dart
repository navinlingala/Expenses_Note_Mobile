import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/investment_model.dart';
import '../../providers/investment_provider.dart';
import 'add_investment_screen.dart';

class InvestmentDetailScreen extends StatefulWidget {
  final String investmentId;
  const InvestmentDetailScreen({super.key, required this.investmentId});

  @override
  State<InvestmentDetailScreen> createState() => _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState extends State<InvestmentDetailScreen> {
  void _showUpdateValuationDialog(BuildContext context, InvestmentModel inv) {
    final controller = TextEditingController(text: inv.currentValue.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Update Current Value'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original Invested: ${CurrencyFormatter.format(inv.investedAmount)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Market Valuation (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter valuation';
                  if (double.tryParse(val.trim()) == null || double.parse(val.trim()) < 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newVal = double.parse(controller.text.trim());
                await context.read<InvestmentProvider>().updateValuation(inv.id, newVal);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Valuation updated to ${CurrencyFormatter.format(newVal)}'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, InvestmentModel inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('Do you want to move "${inv.title}" to the Recycle Bin? You can restore it anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<InvestmentProvider>().softDeleteInvestment(inv.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${inv.title}" moved to Trash.'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.amber,
                      onPressed: () {
                        context.read<InvestmentProvider>().restoreInvestment(inv.id);
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
    final prov = context.watch<InvestmentProvider>();

    final invIndex = prov.allInvestments.indexWhere((i) => i.id == widget.investmentId);
    if (invIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Investment Details')),
        body: const Center(child: Text('Investment not found or deleted.')),
      );
    }

    final inv = prov.allInvestments[invIndex];
    final isProfitable = inv.isProfitable;

    return Scaffold(
      appBar: AppBar(
        title: Text(inv.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Investment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddInvestmentScreen(editInvestment: inv)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E)),
            tooltip: 'Move to Trash',
            onPressed: () => _confirmDelete(context, inv),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Valuation & Return Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(_getCategoryIcon(inv.category), size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            inv.categoryDisplayName,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showUpdateValuationDialog(context, inv),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Update Value',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Market Valuation',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(inv.currentValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isProfitable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isProfitable ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${isProfitable ? "+" : ""}${inv.gainPercentage.toStringAsFixed(2)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${isProfitable ? "+" : ""}${CurrencyFormatter.format(inv.absoluteGain)} total gain',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. CLEAR MONTHLY & YEARLY RETURNS BREAKDOWN
          const Text(
            'Passive Returns Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _returnTile(
                  title: 'Monthly Return',
                  amount: '+${CurrencyFormatter.format(inv.expectedMonthlyReturn)}',
                  subtitle: 'Estimated per month',
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _returnTile(
                  title: 'Yearly Return',
                  amount: '+${CurrencyFormatter.format(inv.expectedAnnualReturn)}',
                  subtitle: 'Estimated per year',
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF0EA5E9),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _metricPill(
                  label: 'Expected Return Rate',
                  value: '${inv.expectedReturnRate.toStringAsFixed(1)}% p.a.',
                  icon: Icons.percent_rounded,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricPill(
                  label: 'Realized CAGR',
                  value: '${inv.realizedCagr.toStringAsFixed(1)}%',
                  icon: Icons.insights_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 3. COMPOUNDING FORECAST PROJECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Compounding Growth Projections',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${inv.expectedReturnRate.toStringAsFixed(1)}% Compounded',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _projectionRow('In 1 Year', inv.projectedValue(1), inv.projectedValue(1) - inv.currentValue, isDark),
                  const Divider(height: 16),
                  _projectionRow('In 3 Years', inv.projectedValue(3), inv.projectedValue(3) - inv.currentValue, isDark),
                  const Divider(height: 16),
                  _projectionRow('In 5 Years', inv.projectedValue(5), inv.projectedValue(5) - inv.currentValue, isDark),
                  const Divider(height: 16),
                  _projectionRow('In 10 Years', inv.projectedValue(10), inv.projectedValue(10) - inv.currentValue, isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 4. Detailed Asset Info
          const Text(
            'Investment Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _infoRow('Invested Principal', CurrencyFormatter.format(inv.investedAmount)),
                _infoRow('Investment Type', inv.investmentType == 'SIP' ? 'Monthly SIP (${CurrencyFormatter.format(inv.sipAmount ?? 0)}/mo)' : 'One-time Lump sum'),
                _infoRow('Investment Date', DateFormat('dd MMMM yyyy').format(inv.startDate)),
                _infoRow('Holding Period', '${inv.holdingDays} days (${inv.holdingYears.toStringAsFixed(1)} years)'),
                if (inv.maturityDate != null)
                  _infoRow('Maturity Date', DateFormat('dd MMMM yyyy').format(inv.maturityDate!)),
                _infoRow('Risk Rating', inv.riskLevel),
                if (inv.notes != null && inv.notes!.isNotEmpty)
                  _infoRow('Notes / Folio', inv.notes!),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _returnTile({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _metricPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectionRow(String timeline, double futureValue, double projectedGain, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeline, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(
              '+${CurrencyFormatter.format(projectedGain)} gain',
              style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
            ),
          ],
        ),
        Text(
          CurrencyFormatter.format(futureValue),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toUpperCase()) {
      case 'MUTUAL_FUNDS':
        return Icons.trending_up_rounded;
      case 'STOCKS':
        return Icons.show_chart_rounded;
      case 'FIXED_DEPOSIT':
        return Icons.lock_clock_rounded;
      case 'GOLD':
        return Icons.monetization_on_rounded;
      case 'REAL_ESTATE':
        return Icons.domain_rounded;
      case 'CRYPTO':
        return Icons.currency_bitcoin_rounded;
      default:
        return Icons.savings_rounded;
    }
  }
}
