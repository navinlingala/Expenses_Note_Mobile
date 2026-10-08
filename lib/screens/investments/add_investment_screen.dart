import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/investment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/investment_provider.dart';

class AddInvestmentScreen extends StatefulWidget {
  final InvestmentModel? editInvestment;
  const AddInvestmentScreen({super.key, this.editInvestment});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _investedAmountController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _expectedRateController = TextEditingController(text: '12.0');
  final _sipAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'MUTUAL_FUNDS';
  String _investmentType = 'LUMPSUM'; // LUMPSUM, SIP
  String _riskLevel = 'MODERATE'; // LOW, MODERATE, HIGH, VERY_HIGH
  String _ratePeriod = 'YEARLY'; // 'YEARLY' or 'MONTHLY'
  DateTime _startDate = DateTime.now();
  DateTime? _maturityDate;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'key': 'MUTUAL_FUNDS', 'label': 'Mutual Funds', 'icon': Icons.trending_up_rounded, 'color': Color(0xFF6366F1)},
    {'key': 'STOCKS', 'label': 'Stocks / Equity', 'icon': Icons.show_chart_rounded, 'color': Color(0xFF0EA5E9)},
    {'key': 'FIXED_DEPOSIT', 'label': 'FD / PPF', 'icon': Icons.lock_clock_rounded, 'color': Color(0xFF10B981)},
    {'key': 'GOLD', 'label': 'Gold / SGB', 'icon': Icons.monetization_on_rounded, 'color': Color(0xFFF59E0B)},
    {'key': 'REAL_ESTATE', 'label': 'Real Estate', 'icon': Icons.domain_rounded, 'color': Color(0xFF8B5CF6)},
    {'key': 'CRYPTO', 'label': 'Crypto', 'icon': Icons.currency_bitcoin_rounded, 'color': Color(0xFFEC4899)},
    {'key': 'OTHER', 'label': 'Other Assets', 'icon': Icons.savings_rounded, 'color': Color(0xFF64748B)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editInvestment != null) {
      final inv = widget.editInvestment!;
      _titleController.text = inv.title;
      _investedAmountController.text = inv.investedAmount.toStringAsFixed(0);
      _currentValueController.text = inv.currentValue.toStringAsFixed(0);
      _expectedRateController.text = inv.expectedReturnRate.toString();
      if (inv.sipAmount != null) {
        _sipAmountController.text = inv.sipAmount!.toStringAsFixed(0);
      }
      _notesController.text = inv.notes ?? '';
      _selectedCategory = inv.category;
      _investmentType = inv.investmentType;
      _riskLevel = inv.riskLevel;
      _startDate = inv.startDate;
      _maturityDate = inv.maturityDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _investedAmountController.dispose();
    _currentValueController.dispose();
    _expectedRateController.dispose();
    _sipAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _parsedInvested => double.tryParse(_investedAmountController.text.trim()) ?? 0.0;
  double get _parsedEnteredRate => double.tryParse(_expectedRateController.text.trim()) ?? 0.0;
  double get _normalizedAnnualRate =>
      _ratePeriod == 'MONTHLY' ? _parsedEnteredRate * 12.0 : _parsedEnteredRate;
  double get _normalizedMonthlyRate =>
      _ratePeriod == 'MONTHLY' ? _parsedEnteredRate : (_parsedEnteredRate / 12.0);
  double get _estAnnualReturn => _parsedInvested * (_normalizedAnnualRate / 100.0);
  double get _estMonthlyReturn => _estAnnualReturn / 12.0;

  void _switchRatePeriod(String period) {
    if (_ratePeriod == period) return;
    final currentVal = double.tryParse(_expectedRateController.text.trim());
    if (currentVal != null && currentVal > 0) {
      if (period == 'MONTHLY') {
        final monthly = currentVal / 12.0;
        _expectedRateController.text =
            monthly.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      } else {
        final yearly = currentVal * 12.0;
        _expectedRateController.text =
            yearly.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      }
    }
    setState(() => _ratePeriod = period);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickMaturityDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _maturityDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() => _maturityDate = picked);
    }
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? 'default_user';

    final invested = double.parse(_investedAmountController.text.trim());
    final currentValText = _currentValueController.text.trim();
    final currentVal = currentValText.isNotEmpty ? double.parse(currentValText) : invested;
    final enteredRate = double.tryParse(_expectedRateController.text.trim()) ?? 0.0;
    final annualRate = _ratePeriod == 'MONTHLY' ? enteredRate * 12.0 : enteredRate;
    final sipText = _sipAmountController.text.trim();
    final sip = sipText.isNotEmpty ? double.tryParse(sipText) : null;

    setState(() => _isLoading = true);

    try {
      final inv = InvestmentModel(
        id: widget.editInvestment?.id ?? const Uuid().v4(),
        userId: userId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        investmentType: _investmentType,
        investedAmount: invested,
        currentValue: currentVal,
        expectedReturnRate: annualRate,
        sipAmount: _investmentType == 'SIP' ? sip : null,
        startDate: _startDate,
        maturityDate: _maturityDate,
        riskLevel: _riskLevel,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: widget.editInvestment?.status ?? 'ACTIVE',
        createdAt: widget.editInvestment?.createdAt,
      );

      final prov = context.read<InvestmentProvider>();
      if (widget.editInvestment == null) {
        await prov.addInvestment(inv);
      } else {
        await prov.updateInvestment(inv);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editInvestment == null
                  ? 'Investment added to portfolio!'
                  : 'Investment updated successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving investment: $e'),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editInvestment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Investment' : 'Add Investment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Category Selector
            const Text(
              'Select Asset Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['key'];
                  final Color color = cat['color'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        cat['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      label: Text(cat['label']),
                      selected: isSelected,
                      selectedColor: color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat['key']),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // 2. Investment Title & Platform
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Asset / Fund Name *',
                hintText: 'e.g. Parag Parikh Flexi Cap, TCS Shares, HDFC FD',
                prefixIcon: Icon(Icons.business_center_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter investment name' : null,
            ),

            const SizedBox(height: 14),

            // 3. Investment Type Toggle (Lump-sum vs SIP)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _investmentType = 'LUMPSUM'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _investmentType == 'LUMPSUM'
                            ? const Color(0xFF6366F1)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _investmentType == 'LUMPSUM'
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'One-time / Lump sum',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _investmentType == 'LUMPSUM' ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _investmentType = 'SIP'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _investmentType == 'SIP'
                            ? const Color(0xFF6366F1)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _investmentType == 'SIP'
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Recurring SIP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _investmentType == 'SIP' ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_investmentType == 'SIP') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _sipAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly SIP Installment (₹/month) *',
                  hintText: '5000',
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
                validator: (v) {
                  if (_investmentType == 'SIP') {
                    if (v == null || v.trim().isEmpty) return 'Enter monthly SIP amount';
                    if (double.tryParse(v) == null) return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 14),

            // 4. Invested Amount & Current Valuation
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _investedAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Invested (₹) *',
                      hintText: '100000',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter amount';
                      if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _currentValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Current Value (₹)',
                      hintText: 'Optional',
                      prefixIcon: Icon(Icons.insights_rounded),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 5. Expected Return Rate (%) with Monthly / Yearly Mode Switcher
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
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
                      const Flexible(
                        child: Text(
                          'Expected Return Rate *',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_ratePeriod == 'MONTHLY' ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _ratePeriod == 'MONTHLY' ? 'Monthly Rate' : 'Annual Rate',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _ratePeriod == 'MONTHLY' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Full-width Responsive Rate Period Switcher
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _switchRatePeriod('YEARLY'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: _ratePeriod == 'YEARLY'
                                    ? const Color(0xFF6366F1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Yearly (% p.a.)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _ratePeriod == 'YEARLY' ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () => _switchRatePeriod('MONTHLY'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: _ratePeriod == 'MONTHLY'
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Monthly (% / mo)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _ratePeriod == 'MONTHLY' ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expectedRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _ratePeriod == 'MONTHLY'
                          ? 'Monthly Rate (% / month)'
                          : 'Annual Rate (% per year / p.a.)',
                      hintText: _ratePeriod == 'MONTHLY' ? '1.0' : '12.0',
                      prefixIcon: Icon(
                        Icons.percent_rounded,
                        color: _ratePeriod == 'MONTHLY' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                      ),
                      suffixText: _ratePeriod == 'MONTHLY' ? '% / mo' : '% p.a.',
                      helperText: _ratePeriod == 'MONTHLY'
                          ? '⚡ ${_parsedEnteredRate.toStringAsFixed(2)}% / mo = ${_normalizedAnnualRate.toStringAsFixed(2)}% / yr'
                          : '⚡ ${_parsedEnteredRate.toStringAsFixed(2)}% p.a. = ${_normalizedMonthlyRate.toStringAsFixed(2)}% / mo',
                      helperStyle: TextStyle(
                        color: _ratePeriod == 'MONTHLY' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter return rate';
                      if (double.tryParse(v) == null) return 'Enter valid percentage';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Live Returns Preview Card
            if (_parsedInvested > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withAlpha(30),
                      const Color(0xFF0EA5E9).withAlpha(20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_graph_rounded, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Estimated Returns',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_ratePeriod == 'MONTHLY' ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _ratePeriod == 'MONTHLY' ? 'Monthly Input' : 'Annual Input',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: _ratePeriod == 'MONTHLY' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Monthly Return',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                  if (_ratePeriod == 'MONTHLY')
                                    const Text(' (Primary)', style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${CurrencyFormatter.format(_estMonthlyReturn)} / mo',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                              Text(
                                'at ${_normalizedMonthlyRate.toStringAsFixed(2)}%/mo',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 36, width: 1, color: Colors.grey.withAlpha(60)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Yearly Return',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                  if (_ratePeriod == 'YEARLY')
                                    const Text(' (Primary)', style: TextStyle(fontSize: 9, color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${CurrencyFormatter.format(_estAnnualReturn)} / yr',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
                              ),
                              Text(
                                'at ${_normalizedAnnualRate.toStringAsFixed(2)}% p.a.',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // 6. Dates Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Investment Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickMaturityDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Maturity (Optional)',
                        prefixIcon: const Icon(Icons.event_available_rounded),
                        suffixIcon: _maturityDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() => _maturityDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _maturityDate != null
                            ? DateFormat('dd MMM yyyy').format(_maturityDate!)
                            : 'None',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 7. Risk Level Selector
            DropdownButtonFormField<String>(
              initialValue: _riskLevel,
              decoration: const InputDecoration(
                labelText: 'Risk Level',
                prefixIcon: Icon(Icons.speed_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Low Risk (Capital Preservation)')),
                DropdownMenuItem(value: 'MODERATE', child: Text('Moderate Risk (Balanced)')),
                DropdownMenuItem(value: 'HIGH', child: Text('High Risk (Equity Growth)')),
                DropdownMenuItem(value: 'VERY_HIGH', child: Text('Very High Risk (Crypto / Speculative)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _riskLevel = val);
              },
            ),

            const SizedBox(height: 14),

            // 8. Platform / Broker & Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Platform, Folio & Notes (Optional)',
                hintText: 'e.g. Zerodha, Folio 1234567, SGB 2026 Series III',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _saveInvestment,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isEditing ? 'Save Changes' : 'Add to Portfolio',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
