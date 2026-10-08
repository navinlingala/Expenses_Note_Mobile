import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/credit_card_transaction_model.dart';
import '../../providers/credit_card_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditCardTransactionScreen extends StatefulWidget {
  final String? preselectedCardId;

  const AddEditCardTransactionScreen({super.key, this.preselectedCardId});

  @override
  State<AddEditCardTransactionScreen> createState() => _AddEditCardTransactionScreenState();
}

class _AddEditCardTransactionScreenState extends State<AddEditCardTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCardId;
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _notesController;
  late TextEditingController _emiMonthsController;
  late TextEditingController _monthlyEmiController;

  String _selectedCategory = 'SHOPPING';
  String _transactionType = 'EXPENSE';
  DateTime _transactionDate = DateTime.now();
  bool _isEmi = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'SHOPPING', 'icon': Icons.shopping_bag_rounded, 'label': 'Shopping'},
    {'name': 'DINING', 'icon': Icons.restaurant_rounded, 'label': 'Dining'},
    {'name': 'GROCERIES', 'icon': Icons.local_grocery_store_rounded, 'label': 'Groceries'},
    {'name': 'FUEL', 'icon': Icons.local_gas_station_rounded, 'label': 'Fuel'},
    {'name': 'BILLS', 'icon': Icons.receipt_rounded, 'label': 'Bills & Utilities'},
    {'name': 'TRAVEL', 'icon': Icons.flight_takeoff_rounded, 'label': 'Travel'},
    {'name': 'ENTERTAINMENT', 'icon': Icons.movie_rounded, 'label': 'Entertainment'},
    {'name': 'HEALTHCARE', 'icon': Icons.medical_services_rounded, 'label': 'Healthcare'},
    {'name': 'OTHER', 'icon': Icons.credit_card_rounded, 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCardId = widget.preselectedCardId;
    _amountController = TextEditingController();
    _merchantController = TextEditingController();
    _notesController = TextEditingController();
    _emiMonthsController = TextEditingController(text: '6');
    _monthlyEmiController = TextEditingController();

    _amountController.addListener(_recalcEmi);
    _emiMonthsController.addListener(_recalcEmi);
  }

  void _recalcEmi() {
    if (_isEmi) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final months = int.tryParse(_emiMonthsController.text) ?? 1;
      if (amount > 0 && months > 0) {
        final monthly = amount / months;
        _monthlyEmiController.text = monthly.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _emiMonthsController.dispose();
    _monthlyEmiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Card Spend / Swipe'),
      ),
      body: Consumer<CreditCardProvider>(
        builder: (context, provider, _) {
          final cards = provider.cards;

          if (cards.isEmpty) {
            return const Center(
              child: Text('No credit cards available. Please add a card first.'),
            );
          }

          if (_selectedCardId == null || !cards.any((c) => c.id == _selectedCardId)) {
            _selectedCardId = cards.first.id;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardSelector(cards, isDark),
                  const SizedBox(height: 16),
                  _buildTypeSelector(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Spend Amount (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter amount';
                      final numVal = double.tryParse(val);
                      if (numVal == null || numVal <= 0) return 'Please enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _merchantController,
                    decoration: const InputDecoration(
                      labelText: 'Merchant / Description *',
                      hintText: 'e.g. Amazon, Swiggy, HP Petrol Pump, Zomato',
                      prefixIcon: Icon(Icons.storefront_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter merchant or description' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryChips(),
                  const SizedBox(height: 16),
                  _buildDatePicker(isDark),
                  const SizedBox(height: 16),
                  _buildEmiSection(isDark),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. 5x reward points promo swipe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTransaction,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded),
                      label: const Text('Record Spend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardSelector(List<dynamic> cards, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCardId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: cards.map<DropdownMenuItem<String>>((c) {
            return DropdownMenuItem<String>(
              value: c.id,
              child: Row(
                children: [
                  const Icon(Icons.credit_card_rounded, color: Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${c.bankName} - ${c.cardName} (${c.last4Digits != null ? '••${c.last4Digits}' : ''})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCardId = val);
          },
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _buildTypeChip('EXPENSE', 'Card Spend', const Color(0xFFEF4444)),
        const SizedBox(width: 10),
        _buildTypeChip('REFUND', 'Refund / Cashback', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label, Color color) {
    final isSelected = _transactionType == type;
    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
              fontSize: 13,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: color,
        onSelected: (selected) {
          if (selected) setState(() => _transactionType = type);
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SPEND CATEGORY',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat['name'];
            return ChoiceChip(
              avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : const Color(0xFF6366F1)),
              label: Text(cat['label'] as String, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
              selected: isSelected,
              selectedColor: const Color(0xFF6366F1),
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategory = cat['name'] as String);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _transactionDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) setState(() => _transactionDate = picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 10),
                Text(
                  'Transaction Date: ${DateFormat('dd MMM yyyy').format(_transactionDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmiSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_rounded, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text('Convert to EMI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Switch.adaptive(
                value: _isEmi,
                activeColor: const Color(0xFF6366F1),
                onChanged: (val) {
                  setState(() {
                    _isEmi = val;
                    _recalcEmi();
                  });
                },
              ),
            ],
          ),
          if (_isEmi) ...[
            const Divider(),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emiMonthsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tenure (Months)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _monthlyEmiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'EMI / Month (₹)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCardId == null) return;

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'guest_user';
    final provider = Provider.of<CreditCardProvider>(context, listen: false);

    final amount = double.parse(_amountController.text.trim());
    final emiMonths = _isEmi ? int.tryParse(_emiMonthsController.text) : null;
    final monthlyEmi = _isEmi ? double.tryParse(_monthlyEmiController.text) : null;

    final tx = CreditCardTransactionModel(
      id: '',
      userId: userId,
      cardId: _selectedCardId!,
      amount: amount,
      merchantName: _merchantController.text.trim(),
      category: _selectedCategory,
      transactionDate: _transactionDate,
      transactionType: _transactionType,
      isEmi: _isEmi,
      emiMonths: emiMonths,
      monthlyEmiAmount: monthlyEmi,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    final success = await provider.addTransaction(tx);
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card transaction recorded!'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record transaction.'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
