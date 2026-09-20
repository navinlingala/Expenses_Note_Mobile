import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

class AddDueScreen extends StatefulWidget {
  final String initialType;
  final TransactionModel? dueToEdit;
  const AddDueScreen({super.key, this.initialType = 'RECEIVABLE', this.dueToEdit});

  @override
  State<AddDueScreen> createState() => _AddDueScreenState();
}

class _AddDueScreenState extends State<AddDueScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _dueDate;

  bool get isEditing => widget.dueToEdit != null;

  @override
  void initState() {
    super.initState();
    final due = widget.dueToEdit;
    if (due != null) {
      _type = due.type;
      _nameController = TextEditingController(text: due.personName ?? due.title);
      _phoneController = TextEditingController(text: due.phoneNumber ?? '');

      String rawNotes = due.notes ?? '';
      String parsedEmail = '';
      if (rawNotes.toLowerCase().contains('email:')) {
        for (final line in rawNotes.split('\n')) {
          if (line.trim().toLowerCase().startsWith('email:')) {
            parsedEmail = line.trim().substring(6).trim();
          }
        }
        rawNotes = rawNotes
            .split('\n')
            .where((l) => !l.trim().toLowerCase().startsWith('email:'))
            .join('\n')
            .trim();
      }

      _emailController = TextEditingController(text: parsedEmail);
      _amountController = TextEditingController(
        text: due.amount == due.amount.roundToDouble()
            ? due.amount.toInt().toString()
            : due.amount.toString(),
      );
      _notesController = TextEditingController(text: rawNotes);
      _dueDate = due.dueDate;
    } else {
      _type = widget.initialType;
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _emailController = TextEditingController();
      _amountController = TextEditingController();
      _notesController = TextEditingController();
      _dueDate = DateTime.now().add(const Duration(days: 3));
    }

    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveDue() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim();

    String fullNotes = notes;
    if (email.isNotEmpty) {
      fullNotes = fullNotes.isEmpty ? 'Email: $email' : 'Email: $email\n$fullNotes';
    }

    final userId = context.read<AuthProvider>().currentUser?.id ?? 'default_user';

    if (isEditing) {
      final updatedTx = widget.dueToEdit!.copyWith(
        title: _type == 'RECEIVABLE' ? '$name owes me' : 'I owe $name',
        personName: name,
        phoneNumber: phone.isEmpty ? null : phone,
        amount: amount,
        type: _type,
        dueDate: _dueDate,
        notes: fullNotes.isEmpty ? null : fullNotes,
      );

      await context.read<TransactionProvider>().updateTransaction(updatedTx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Due details for "$name" updated successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      await context.read<TransactionProvider>().addTransaction(
            userId: userId,
            title: _type == 'RECEIVABLE' ? '$name owes me' : 'I owe $name',
            personName: name,
            phoneNumber: phone.isEmpty ? null : phone,
            amount: amount,
            type: _type,
            dueDate: _dueDate,
            notes: fullNotes.isEmpty ? null : fullNotes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _type == 'RECEIVABLE'
                  ? 'Receivable from $name recorded with WhatsApp reminders!'
                  : 'Payable to $name recorded!',
            ),
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
    final currentAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Due & Person Details' : 'Add Money Owed / Due'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Segmented Type Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'RECEIVABLE'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'RECEIVABLE' ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Who Owes Me (Receive)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _type == 'RECEIVABLE' ? Colors.white : (isDark ? Colors.white60 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'PAYABLE'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'PAYABLE' ? const Color(0xFFF43F5E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Whom I Owe (Pay)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _type == 'PAYABLE' ? Colors.white : (isDark ? Colors.white60 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Person Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Person Name',
                hintText: 'e.g. Omkar, Ravi, Suresh',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter person name' : null,
            ),
            const SizedBox(height: 14),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number (WhatsApp Alerts)',
                hintText: 'e.g. 9876543210',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // Email Address
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address (Optional)',
                hintText: 'e.g. omkar@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Due Amount (₹)',
                hintText: '1500',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final parsed = double.tryParse(val);
                if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Due Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
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
                    const Icon(Icons.event_rounded, color: Color(0xFF6366F1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Expected Due Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            AppDateUtils.formatShort(_dueDate),
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
            const SizedBox(height: 14),

            // Reason / Note
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason / Terms / Notes (Optional)',
                hintText: 'e.g. Lent for travel, partial payment history, terms',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // Live Preview Card
            if (currentAmount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_type == 'RECEIVABLE' ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_type == 'RECEIVABLE' ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _type == 'RECEIVABLE' ? 'To Receive:' : 'To Pay:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      CurrencyFormatter.format(currentAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _type == 'RECEIVABLE' ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveDue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'RECEIVABLE' ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isEditing
                    ? 'Update Due Details'
                    : (_type == 'RECEIVABLE' ? 'Save Receivable (To Receive)' : 'Save Payable (To Pay)'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
