import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/income_source_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/income_provider.dart';

class FamilyIncomeScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const FamilyIncomeScreen({super.key, this.onOpenDrawer});

  @override
  State<FamilyIncomeScreen> createState() => _FamilyIncomeScreenState();
}

class _FamilyIncomeScreenState extends State<FamilyIncomeScreen> {
  void _showAddOrEditIncomeModal(BuildContext context, [IncomeSourceModel? incomeToEdit]) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final isEdit = incomeToEdit != null;
    final earnerCtrl = TextEditingController(text: incomeToEdit?.earnerName ?? 'Self');
    final titleCtrl = TextEditingController(text: incomeToEdit?.sourceTitle ?? '');
    final amountCtrl = TextEditingController(text: incomeToEdit != null ? incomeToEdit.amount.toStringAsFixed(0) : '');
    final dayCtrl = TextEditingController(text: incomeToEdit != null ? incomeToEdit.payoutDay.toString() : '1');
    final notesCtrl = TextEditingController(text: incomeToEdit?.notes ?? '');
    String selectedCategory = incomeToEdit?.category ?? 'SALARY';
    final formKey = GlobalKey<FormState>();

    final quickMembers = ['Self', 'Spouse', 'Father', 'Mother', 'Rental Property', 'Business'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Income Source' : 'Add Family & Salary Inflow',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Member Select Chips
                  const Text('Who is Earning?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickMembers.map((name) {
                        final isSelected = earnerCtrl.text == name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  earnerCtrl.text = name;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: earnerCtrl,
                    decoration: InputDecoration(
                      labelText: 'Earner / Member Name',
                      hintText: 'e.g. Self, Spouse, Father',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter member name' : null,
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Income Source Title',
                      hintText: 'e.g. Software Engineer Job, Pension, Shop Revenue',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.work_outline_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter income title' : null,
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Monthly Inflow (₹)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.currency_rupee_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter amount';
                            final val = double.tryParse(v);
                            if (val == null || val <= 0) return 'Valid amount';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: dayCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Payout Day',
                            hintText: '1 - 31',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.calendar_today_rounded),
                          ),
                          validator: (v) {
                            final d = int.tryParse(v ?? '');
                            if (d == null || d < 1 || d > 31) return '1 - 31';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Income Stream Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SALARY', child: Text('Primary Salary / Wages')),
                      DropdownMenuItem(value: 'BUSINESS', child: Text('Business / Trade Profit')),
                      DropdownMenuItem(value: 'RENTAL', child: Text('Rental Income (Real Estate)')),
                      DropdownMenuItem(value: 'PENSION', child: Text('Government / Private Pension')),
                      DropdownMenuItem(value: 'FREELANCE', child: Text('Freelancing / Side Gig')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other Constant Earnings')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. Credited via direct bank transfer',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final amount = double.parse(amountCtrl.text.trim());
                          final day = int.parse(dayCtrl.text.trim());
                          final incProv = context.read<IncomeProvider>();

                          if (isEdit) {
                            final updated = incomeToEdit.copyWith(
                              earnerName: earnerCtrl.text.trim(),
                              sourceTitle: titleCtrl.text.trim(),
                              amount: amount,
                              payoutDay: day,
                              category: selectedCategory,
                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            );
                            await incProv.updateIncome(updated);
                          } else {
                            await incProv.addIncome(
                              userId: user.id,
                              earnerName: earnerCtrl.text.trim(),
                              sourceTitle: titleCtrl.text.trim(),
                              amount: amount,
                              payoutDay: day,
                              category: selectedCategory,
                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            );
                          }

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Income updated!' : 'Household earnings added!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        isEdit ? 'Update Earnings' : 'Save Income Source',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, IncomeSourceModel income) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Income Source?'),
        content: Text('Remove "${income.sourceTitle} (${income.earnerName})" from active household earnings?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<IncomeProvider>().softDeleteIncome(income.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incProv = context.watch<IncomeProvider>();
    final activeIncomes = incProv.activeIncomes;

    final totalMonthly = incProv.totalMonthlyIncome;
    final selfTotal = incProv.selfMonthlyIncome;
    final familyTotal = incProv.familyMonthlyIncome;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Open Side Menu',
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
            const Text('Family & Salary Earnings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(
              'Total Monthly Inflow: ${CurrencyFormatter.format(totalMonthly)}',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Income Source', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddOrEditIncomeModal(context),
      ),
      body: activeIncomes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 48),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No Salary or Family Inflows Added',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your monthly salary, spouse earnings, rental, or family income to see true savings and net household cashflow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add First Income Source', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showAddOrEditIncomeModal(context),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Total Inflow Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Household Monthly Inflow',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(totalMonthly),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Self: ${CurrencyFormatter.format(selfTotal)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Family / Other: ${CurrencyFormatter.format(familyTotal)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text('Active Earnings Streams', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),

                ...activeIncomes.map((income) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF10B981).withAlpha(25),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      title: Text(income.sourceTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      subtitle: Text(
                        '${income.earnerName} • Due Day ${income.payoutDay} of month',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.format(income.amount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 20),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showAddOrEditIncomeModal(context, income);
                              } else if (val == 'delete') {
                                _confirmDelete(context, income);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Color(0xFFF43F5E)), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Color(0xFFF43F5E)))]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
