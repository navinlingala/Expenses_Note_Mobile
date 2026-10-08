import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/child_expense_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditChildExpenseScreen extends StatefulWidget {
  final ChildExpenseModel? expense;
  final String? preselectedChildId;

  const AddEditChildExpenseScreen({super.key, this.expense, this.preselectedChildId});

  @override
  State<AddEditChildExpenseScreen> createState() => _AddEditChildExpenseScreenState();
}

class _AddEditChildExpenseScreenState extends State<AddEditChildExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  String? _childId;
  String _category = 'EDUCATION';
  DateTime _expenseDate = DateTime.now();
  String _paymentMode = 'UPI';
  bool _isRecurring = false;
  String _recurrenceFrequency = 'MONTHLY';
  bool _isSaving = false;

  final List<String> _paymentModes = ['UPI', 'CASH', 'CARD', 'NET_BANKING'];

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'EDUCATION',
      'label': 'Education & School',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 'HEALTHCARE',
      'label': 'Health & Medical',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFFEF4444),
    },
    {
      'id': 'CHILDCARE',
      'label': 'Daily Care & Toys',
      'icon': Icons.toys_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'EVENTS',
      'label': 'Events & Outings',
      'icon': Icons.celebration_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'ALLOWANCE',
      'label': 'Pocket Money',
      'icon': Icons.savings_rounded,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'OTHERS',
      'label': 'Other Expenses',
      'icon': Icons.category_rounded,
      'color': const Color(0xFF6B7280),
    },
  ];

  @override
  void initState() {
    super.initState();
    final exp = widget.expense;
    _titleController = TextEditingController(text: exp?.title ?? '');
    _amountController = TextEditingController(
      text: exp != null ? exp.amount.toStringAsFixed(0) : '',
    );
    _notesController = TextEditingController(text: exp?.notes ?? '');

    if (exp != null) {
      _childId = exp.childId;
      _category = exp.category;
      _expenseDate = exp.expenseDate;
      _paymentMode = exp.paymentMode;
      _isRecurring = exp.isRecurring;
      _recurrenceFrequency = exp.recurrenceFrequency;
    } else {
      _childId = widget.preselectedChildId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    if (_childId == null || _childId!.isEmpty) {
      if (childProvider.profiles.isNotEmpty) {
        _childId = childProvider.profiles.first.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add a child profile first!', style: GoogleFonts.outfit()),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'default_user';

    final isEdit = widget.expense != null;
    final exp = ChildExpenseModel(
      id: isEdit ? widget.expense!.id : const Uuid().v4(),
      childId: _childId!,
      userId: userId,
      title: _titleController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
      category: _category,
      expenseDate: _expenseDate,
      paymentMode: _paymentMode,
      isRecurring: _isRecurring,
      recurrenceFrequency: _isRecurring ? _recurrenceFrequency : 'NONE',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: isEdit ? widget.expense!.createdAt : DateTime.now(),
    );

    bool success;
    if (isEdit) {
      success = await childProvider.updateChildExpense(exp);
    } else {
      success = await childProvider.addChildExpense(exp);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Expense updated successfully' : 'Child expense recorded successfully',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: ${childProvider.errorMessage ?? "Unknown error"}',
                style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.expense != null;
    final childProvider = Provider.of<ChildProvider>(context);
    final profiles = childProvider.profiles;

    if (_childId == null && profiles.isNotEmpty) {
      _childId = profiles.first.id;
    }

    final selectedCatMeta = _categories.firstWhere(
      (c) => c['id'] == _category,
      orElse: () => _categories.first,
    );
    final themeColor = selectedCatMeta['color'] as Color;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Child Expense' : 'Add Child Expense',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child Profile Selector Dropdown
              if (profiles.isNotEmpty) ...[
                Text(
                  'Select Child *',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _childId,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: profiles.map((p) {
                        final childColor = Color(int.parse(p.avatarColor));
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: childColor,
                                child: Icon(
                                  p.gender == 'FEMALE' ? Icons.face_3_rounded : Icons.face_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${p.name} (${p.formattedAge})',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _childId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Expense Title
              _buildTextCard(
                label: 'Expense Description / Title *',
                controller: _titleController,
                hint: 'e.g. Q1 School Term Fee, Pediatrician checkup, Books',
                icon: Icons.edit_note_rounded,
                isDark: isDark,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter expense title';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Amount Card
              _buildTextCard(
                label: 'Amount (₹) *',
                controller: _amountController,
                hint: '0',
                icon: Icons.currency_rupee_rounded,
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter amount';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Please enter a valid amount';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category Selector Chips
              Text(
                'Expense Category *',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat['id'];
                  final col = cat['color'] as Color;
                  return InkWell(
                    onTap: () => setState(() => _category = cat['id'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? col.withAlpha(isDark ? 55 : 30)
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? col : (isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'] as IconData, size: 16, color: isSelected ? col : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            cat['label'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? col : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Expense Date Picker
              Text(
                'Expense Date',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMMM yyyy').format(_expenseDate),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Payment Mode Chips
              Text(
                'Payment Mode',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paymentModes.map((mode) {
                  final isSelected = _paymentMode == mode;
                  return InkWell(
                    onTap: () => setState(() => _paymentMode = mode),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeColor.withAlpha(isDark ? 50 : 25)
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? themeColor : (isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Text(
                        mode,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? themeColor : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Recurring Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded, size: 20, color: themeColor),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recurring Expense',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'e.g. Monthly tuition, Daycare',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRecurring,
                      activeColor: themeColor,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                  ],
                ),
              ),

              if (_isRecurring) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ['MONTHLY', 'QUARTERLY', 'YEARLY'].map((freq) {
                    final isSel = _recurrenceFrequency == freq;
                    return ChoiceChip(
                      label: Text(freq, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: isSel,
                      selectedColor: themeColor.withAlpha(60),
                      onSelected: (_) => setState(() => _recurrenceFrequency = freq),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Notes
              _buildTextCard(
                label: 'Notes / Invoice / Comments (Optional)',
                controller: _notesController,
                hint: 'e.g. Receipt No #204, Term 1 books fee',
                icon: Icons.notes_rounded,
                isDark: isDark,
                maxLines: 2,
              ),

              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isEdit ? Icons.check_circle_rounded : Icons.add_circle_rounded, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEdit ? 'Update Expense' : 'Save Child Expense',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextCard({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withAlpha(15)),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
              prefixIcon: Icon(icon, size: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
