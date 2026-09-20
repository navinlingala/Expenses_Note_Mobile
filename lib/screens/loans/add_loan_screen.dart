import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/loan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanModel? loanToEdit;
  const AddLoanScreen({super.key, this.loanToEdit});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _lenderController;
  late final TextEditingController _principalController;
  late final TextEditingController _emiAmountController;
  late final TextEditingController _tenureController;
  late final TextEditingController _paidEmisController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _notesController;

  late DateTime _startDate;
  late List<int> _selectedOffsets;

  bool get isEditing => widget.loanToEdit != null;

  @override
  void initState() {
    super.initState();
    final loan = widget.loanToEdit;
    if (loan != null) {
      _titleController = TextEditingController(text: loan.title);
      _lenderController = TextEditingController(text: loan.lenderName);
      _principalController = TextEditingController(
        text: loan.totalPrincipal == loan.totalPrincipal.roundToDouble()
            ? loan.totalPrincipal.toInt().toString()
            : loan.totalPrincipal.toString(),
      );
      _emiAmountController = TextEditingController(
        text: loan.emiAmount == loan.emiAmount.roundToDouble()
            ? loan.emiAmount.toInt().toString()
            : loan.emiAmount.toString(),
      );
      _tenureController = TextEditingController(text: loan.totalEmis.toString());
      _paidEmisController = TextEditingController(text: loan.paidEmis.toString());
      _dueDayController = TextEditingController(text: loan.dueDay.toString());
      _notesController = TextEditingController(text: loan.notes ?? '');
      _startDate = loan.startDate;
      _selectedOffsets = List<int>.from(loan.reminderOffsets);
    } else {
      _titleController = TextEditingController();
      _lenderController = TextEditingController();
      _principalController = TextEditingController();
      _emiAmountController = TextEditingController();
      _tenureController = TextEditingController(text: '24');
      _paidEmisController = TextEditingController(text: '0');
      _dueDayController = TextEditingController(text: '5');
      _notesController = TextEditingController();
      _startDate = DateTime.now();
      _selectedOffsets = [7, 2, 1, 0];
    }

    _tenureController.addListener(() => setState(() {}));
    _paidEmisController.addListener(() => setState(() {}));
    _emiAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lenderController.dispose();
    _principalController.dispose();
    _emiAmountController.dispose();
    _tenureController.dispose();
    _paidEmisController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _elapsedMonthsFromStart {
    final now = DateTime.now();
    final diff = (now.year - _startDate.year) * 12 + (now.month - _startDate.month);
    return diff > 0 ? diff : 0;
  }

  void _saveLoan() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final lender = _lenderController.text.trim();
    final principal = double.tryParse(_principalController.text.trim()) ?? 0.0;
    final emi = double.tryParse(_emiAmountController.text.trim()) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 12;
    final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
    final dueDay = int.tryParse(_dueDayController.text.trim()) ?? 5;
    final remaining = (tenure - paidEmis).clamp(0, tenure);
    final status = remaining == 0 ? 'COMPLETED' : 'ACTIVE';

    final userId = context.read<AuthProvider>().currentUser?.id ?? 'default_user';

    if (isEditing) {
      final updated = widget.loanToEdit!.copyWith(
        title: title,
        lenderName: lender,
        totalPrincipal: principal,
        emiAmount: emi,
        totalEmis: tenure,
        remainingEmis: remaining,
        dueDay: dueDay.clamp(1, 31),
        startDate: _startDate,
        reminderOffsets: _selectedOffsets,
        status: status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await context.read<LoanProvider>().updateLoan(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loan "$title" updated! ($paidEmis paid, $remaining remaining)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      await context.read<LoanProvider>().addLoan(
            userId: userId,
            title: title,
            lenderName: lender,
            totalPrincipal: principal,
            emiAmount: emi,
            totalEmis: tenure,
            paidEmis: paidEmis,
            dueDay: dueDay.clamp(1, 31),
            startDate: _startDate,
            reminderOffsets: _selectedOffsets,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loan "$title" saved! ($paidEmis paid, $remaining remaining)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalTenure = int.tryParse(_tenureController.text.trim()) ?? 0;
    final paidCount = int.tryParse(_paidEmisController.text.trim()) ?? 0;
    final emiVal = double.tryParse(_emiAmountController.text.trim()) ?? 0.0;
    final remainingCount = (totalTenure - paidCount).clamp(0, totalTenure > 0 ? totalTenure : 0);
    final remainingBal = remainingCount * emiVal;
    final clearedAmount = paidCount * emiVal;
    final progress = totalTenure > 0 ? (paidCount / totalTenure).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Personal Loan / EMI' : 'Add Personal Loan / EMI'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Loan Title',
                hintText: 'e.g. Personal Loan, Car Loan, Home Loan',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _lenderController,
              decoration: const InputDecoration(
                labelText: 'Bank / Lender Name',
                hintText: 'e.g. Piramal, HDFC Bank, SBI, Friend',
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter lender name' : null,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _principalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Loan (₹)',
                      hintText: 'e.g. 1673160',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emiAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'EMI Amount (₹)',
                      hintText: 'e.g. 27886',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tenureController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total EMIs (Tenure)',
                      hintText: 'e.g. 60',
                      prefixIcon: Icon(Icons.timelapse_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final parsed = int.tryParse(val);
                      if (parsed == null || parsed <= 0) return 'Invalid tenure';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dueDayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Due Day of Month',
                      hintText: '5 (e.g. 5th)',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    validator: (val) {
                      final parsed = int.tryParse(val ?? '');
                      if (parsed == null || parsed < 1 || parsed > 31) return 'Day 1-31';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Already Paid EMIs field
            TextFormField(
              controller: _paidEmisController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Already Paid / Cleared EMIs',
                hintText: 'e.g. 24 (if taken 2 years back)',
                helperText: 'Number of EMIs already cleared before tracking in app',
                prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  tooltip: 'If you started the loan in the past, enter how many monthly EMIs are already completed.',
                  onPressed: () {},
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required (enter 0 if new)';
                final parsed = int.tryParse(val);
                if (parsed == null || parsed < 0) return 'Must be 0 or greater';
                final total = int.tryParse(_tenureController.text.trim()) ?? 0;
                if (total > 0 && parsed > total) return 'Cannot exceed total EMIs ($total)';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Live Calculation Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
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
                        '📊 Loan Status Preview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: remainingCount == 0
                              ? const Color(0xFF10B981).withAlpha(30)
                              : const Color(0xFF6366F1).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          remainingCount == 0 ? 'COMPLETED' : 'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: remainingCount == 0 ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cleared EMIs', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                          Text(
                            '$paidCount of $totalTenure (${(progress * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                          ),
                          if (emiVal > 0)
                            Text(
                              CurrencyFormatter.format(clearedAmount),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Remaining Balance', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                          Text(
                            '$remainingCount EMIs left',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                          ),
                          if (emiVal > 0)
                            Text(
                              CurrencyFormatter.format(remainingBal),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Start Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2010),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155).withAlpha(128) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, color: Color(0xFF6366F1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Loan Start Date (When loan was taken)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            AppDateUtils.formatShort(_startDate),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),

            // Quick Auto-calculate suggestion chip if start date is in the past
            if (_elapsedMonthsFromStart > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.auto_fix_high_rounded, size: 16, color: Color(0xFF6366F1)),
                  label: Text('Auto-fill $_elapsedMonthsFromStart cleared EMIs from start date'),
                  backgroundColor: const Color(0xFF6366F1).withAlpha(25),
                  onPressed: () {
                    final tenure = int.tryParse(_tenureController.text.trim()) ?? 0;
                    final capped = tenure > 0 ? _elapsedMonthsFromStart.clamp(0, tenure) : _elapsedMonthsFromStart;
                    _paidEmisController.text = capped.toString();
                    setState(() {});
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Multiple Reminders Selector
            const Text(
              'Multiple Automated Reminders',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Select when you want to receive mobile notifications/alarms:',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: [
                _offsetChip(7, '7 days before'),
                _offsetChip(3, '3 days before'),
                _offsetChip(2, '2 days before'),
                _offsetChip(1, '24 hours before'),
                _offsetChip(0, 'Due date morning (9 AM)'),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Account number, interest rate or terms',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _saveLoan,
              child: Text(isEditing ? 'Update Loan Details' : 'Save Loan & Schedule Reminders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offsetChip(int days, String label) {
    final isSelected = _selectedOffsets.contains(days);
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedOffsets.add(days);
          } else {
            if (_selectedOffsets.length > 1) {
              _selectedOffsets.remove(days);
            }
          }
        });
      },
      selectedColor: const Color(0xFF6366F1).withAlpha(40),
      checkmarkColor: const Color(0xFF6366F1),
    );
  }
}
