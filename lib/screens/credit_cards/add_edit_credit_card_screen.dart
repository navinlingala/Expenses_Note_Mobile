import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/credit_card_model.dart';
import '../../providers/credit_card_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditCreditCardScreen extends StatefulWidget {
  final CreditCardModel? existingCard;

  const AddEditCreditCardScreen({super.key, this.existingCard});

  @override
  State<AddEditCreditCardScreen> createState() => _AddEditCreditCardScreenState();
}

class _AddEditCreditCardScreenState extends State<AddEditCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cardNameController;
  late TextEditingController _bankNameController;
  late TextEditingController _cardNumberController;
  late TextEditingController _cardHolderController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _cardPinController;
  late TextEditingController _last4Controller;
  late TextEditingController _totalLimitController;
  late TextEditingController _currentOutstandingController;
  late TextEditingController _notesController;

  String _selectedNetwork = 'VISA';
  String _selectedColorTheme = 'BLUE_PURPLE';
  int _statementDay = 15;
  int _dueDay = 5;
  bool _reminderEnabled = true;
  bool _isSaving = false;
  bool _showSecretInfo = false;
  bool _showCvv = false;
  bool _showPin = false;

  final List<String> _popularBanks = [
    'HDFC Bank',
    'SBI Card',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra',
    'OneCard',
    'American Express',
    'IndusInd Bank',
    'RBL Bank',
    'Bank of Baroda',
    'Federal Bank',
    'Standard Chartered',
    'IDFC FIRST Bank',
    'AU Small Finance',
  ];

  final List<String> _networks = ['VISA', 'MASTERCARD', 'RUPAY', 'AMEX', 'DINERS'];

  final Map<String, List<Color>> _themePresets = {
    'BLUE_PURPLE': [const Color(0xFF312E81), const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
    'EMERALD': [const Color(0xFF065F46), const Color(0xFF047857), const Color(0xFF10B981)],
    'MIDNIGHT_GOLD': [const Color(0xFF1F2937), const Color(0xFF374151), const Color(0xFFD97706)],
    'CRIMSON': [const Color(0xFF881337), const Color(0xFFBE123C), const Color(0xFFE11D48)],
    'SUNSET': [const Color(0xFF7C2D12), const Color(0xFFC2410C), const Color(0xFFF97316)],
    'OBSIDIAN': [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
    'ROYAL_BLUE': [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
  };

  @override
  void initState() {
    super.initState();
    final card = widget.existingCard;
    _cardNameController = TextEditingController(text: card?.cardName ?? '');
    _bankNameController = TextEditingController(text: card?.bankName ?? 'HDFC Bank');
    _cardNumberController = TextEditingController(text: card?.cardNumber ?? '');
    _cardHolderController = TextEditingController(text: card?.cardHolderName ?? '');
    _expiryController = TextEditingController(text: card?.expiryDate ?? '');
    _cvvController = TextEditingController(text: card?.cvv ?? '');
    _cardPinController = TextEditingController(text: card?.cardPin ?? '');
    _last4Controller = TextEditingController(text: card?.last4Digits ?? '');
    _totalLimitController = TextEditingController(text: card != null ? card.totalLimit.toStringAsFixed(0) : '');
    _currentOutstandingController = TextEditingController(
      text: card != null ? card.currentOutstanding.toStringAsFixed(0) : '0',
    );
    _notesController = TextEditingController(text: card?.notes ?? '');

    if (card != null) {
      _selectedNetwork = card.cardNetwork;
      _selectedColorTheme = card.colorTheme;
      _statementDay = card.statementDay;
      _dueDay = card.dueDay;
      _reminderEnabled = card.reminderEnabled;
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _bankNameController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardPinController.dispose();
    _last4Controller.dispose();
    _totalLimitController.dispose();
    _currentOutstandingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _formatCardNumber(String value) {
    String clean = value.replaceAll(RegExp(r'\s+'), '');
    if (clean.length > 16) clean = clean.substring(0, 16);

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    final formatted = buffer.toString();
    if (_cardNumberController.text != formatted) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (clean.length >= 4) {
      _last4Controller.text = clean.substring(clean.length - 4);
    }
    setState(() {});
  }

  void _formatExpiry(String value) {
    String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length > 4) clean = clean.substring(0, 4);

    String formatted = clean;
    if (clean.length >= 3) {
      formatted = '${clean.substring(0, 2)}/${clean.substring(2)}';
    }
    if (_expiryController.text != formatted) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingCard != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Credit Card' : 'Add Credit Card'),
        actions: [
          IconButton(
            icon: Icon(_showSecretInfo ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            tooltip: _showSecretInfo ? 'Hide Card Numbers' : 'Reveal Card Numbers',
            onPressed: () => setState(() => _showSecretInfo = !_showSecretInfo),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLivePreviewCard(isDark),
              const SizedBox(height: 20),

              _buildSectionTitle('CARD DETAILS'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Card Name / Variant *',
                  hintText: 'e.g. Regalia Gold, Amazon Pay, Millennia',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter card name' : null,
              ),
              const SizedBox(height: 14),
              _buildBankSelector(isDark),
              const SizedBox(height: 14),
              _buildNetworkSelector(),
              const SizedBox(height: 20),

              // SECURE CARD NUMBER & CVV VAULT SECTION
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withAlpha(isDark ? 80 : 50),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6366F1), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Card Number & Security Code',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Stored encrypted & masked for quick shopping checkout',
                                style: TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(_showSecretInfo ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF6366F1), size: 20),
                          tooltip: _showSecretInfo ? 'Hide' : 'Show',
                          onPressed: () => setState(() => _showSecretInfo = !_showSecretInfo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Card Number
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      obscureText: !_showSecretInfo,
                      decoration: InputDecoration(
                        labelText: 'Full Card Number (Optional)',
                        hintText: '4532 8901 2345 6789',
                        prefixIcon: const Icon(Icons.payment_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_showSecretInfo ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _showSecretInfo = !_showSecretInfo),
                        ),
                      ),
                      onChanged: _formatCardNumber,
                    ),
                    const SizedBox(height: 12),

                    // Card Holder Name
                    TextFormField(
                      controller: _cardHolderController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Card Holder Name (Optional)',
                        hintText: 'e.g. NAVEEN KUMAR',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Expiry, CVV & ATM PIN Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            decoration: const InputDecoration(
                              labelText: 'Expiry',
                              hintText: 'MM/YY',
                              prefixIcon: Icon(Icons.calendar_today_rounded),
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                            onChanged: _formatExpiry,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: !_showCvv,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              hintText: '•••',
                              prefixIcon: const Icon(Icons.security_rounded),
                              border: const OutlineInputBorder(),
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(_showCvv ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                                onPressed: () => setState(() => _showCvv = !_showCvv),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cardPinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: !_showPin,
                            decoration: InputDecoration(
                              labelText: 'PIN (ATM)',
                              hintText: '••••',
                              prefixIcon: const Icon(Icons.pin_rounded),
                              border: const OutlineInputBorder(),
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                                onPressed: () => setState(() => _showPin = !_showPin),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('LIMITS & OUTSTANDING BALANCE'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalLimitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Limit (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter limit';
                        final numVal = double.tryParse(val);
                        if (numVal == null || numVal <= 0) return 'Invalid limit';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currentOutstandingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Outstanding (₹)',
                        prefixIcon: Icon(Icons.receipt_long_rounded),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('BILLING CYCLE & REMINDERS'),
              const SizedBox(height: 10),
              _buildCycleDayPickers(isDark),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                title: const Text('Statement & Due Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Notify before bill generation date and payment due date'),
                value: _reminderEnabled,
                activeColor: const Color(0xFF6366F1),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _reminderEnabled = val),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('CARD COLOR THEME'),
              const SizedBox(height: 10),
              _buildThemeSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Reward Milestones (Optional)',
                  hintText: 'e.g. ₹1.5L spend fee waiver, 5% cashback on Amazon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCard,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    isEditing ? 'Update Credit Card' : 'Save Credit Card',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildLivePreviewCard(bool isDark) {
    final gradients = _themePresets[_selectedColorTheme] ?? _themePresets['BLUE_PURPLE']!;
    final bank = _bankNameController.text.trim().isEmpty ? 'BANK NAME' : _bankNameController.text.trim();
    final name = _cardNameController.text.trim().isEmpty ? 'Credit Card' : _cardNameController.text.trim();
    final holder = _cardHolderController.text.trim().isEmpty ? 'CARD HOLDER' : _cardHolderController.text.trim();
    final expiry = _expiryController.text.trim().isEmpty ? 'MM/YY' : _expiryController.text.trim();
    
    String displayCardNum = '•••• •••• •••• ••••';
    if (_cardNumberController.text.isNotEmpty) {
      if (_showSecretInfo) {
        displayCardNum = _cardNumberController.text;
      } else {
        final clean = _cardNumberController.text.replaceAll(RegExp(r'\s+'), '');
        final first4 = clean.length >= 4 ? clean.substring(0, 4) : '••••';
        final last4 = clean.length >= 8 ? clean.substring(clean.length - 4) : '••••';
        displayCardNum = '$first4 •••• •••• $last4';
      }
    } else if (_last4Controller.text.isNotEmpty) {
      displayCardNum = '•••• •••• •••• ${_last4Controller.text}';
    }

    final totalLimit = double.tryParse(_totalLimitController.text) ?? 0.0;
    final outstanding = double.tryParse(_currentOutstandingController.text) ?? 0.0;
    final available = (totalLimit - outstanding).clamp(0.0, double.infinity);

    return Container(
      height: 205,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradients.first.withAlpha(isDark ? 90 : 120),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      _selectedNetwork,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // EMV CHIP & CARD NUMBER
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.credit_card, size: 16, color: Colors.black54),
                  ),
                  const Icon(Icons.contactless_rounded, color: Colors.white70, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayCardNum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  if (_cvvController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        'CVV: ${_showCvv ? _cvvController.text : "•••"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // BOTTOM ROW: HOLDER, EXPIRY & AVAILABLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CARD HOLDER', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                    Text(
                      holder.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('EXPIRES', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                    Text(
                      expiry,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('AVAILABLE', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹${available.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildBankSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _bankNameController,
          decoration: const InputDecoration(
            labelText: 'Bank Name *',
            hintText: 'e.g. HDFC Bank, SBI, ICICI',
            prefixIcon: Icon(Icons.account_balance_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter bank name' : null,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _popularBanks.map((bank) {
              final isSelected = _bankNameController.text.trim() == bank;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(bank, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _bankNameController.text = bank;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Card Network / Payment Gateway', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: _networks.map((net) {
            final isSelected = _selectedNetwork == net;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => setState(() => _selectedNetwork = net),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6366F1).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6366F1).withAlpha(50),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      net,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCycleDayPickers(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statement Generation Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Day of month bill is generated', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              DropdownButton<int>(
                value: _statementDay,
                items: List.generate(31, (i) => i + 1).map((d) {
                  return DropdownMenuItem(value: d, child: Text('$d${_getDaySuffix(d)}'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _statementDay = val);
                },
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Due Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Last day to pay bill without interest', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              DropdownButton<int>(
                value: _dueDay,
                items: List.generate(31, (i) => i + 1).map((d) {
                  return DropdownMenuItem(value: d, child: Text('$d${_getDaySuffix(d)}'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _dueDay = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildThemeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _themePresets.entries.map((entry) {
          final isSelected = _selectedColorTheme == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedColorTheme = entry.key),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: entry.value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: entry.value.first.withAlpha(150), blurRadius: 8, spreadRadius: 2)]
                    : null,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'guest_user';
    final provider = Provider.of<CreditCardProvider>(context, listen: false);

    final totalLimit = double.parse(_totalLimitController.text.trim());
    final outstanding = double.tryParse(_currentOutstandingController.text.trim()) ?? 0.0;
    final available = (totalLimit - outstanding).clamp(0.0, double.infinity);

    final card = CreditCardModel(
      id: widget.existingCard?.id ?? '',
      userId: userId,
      cardName: _cardNameController.text.trim(),
      bankName: _bankNameController.text.trim(),
      cardNetwork: _selectedNetwork,
      cardNumber: _cardNumberController.text.trim().isNotEmpty ? _cardNumberController.text.trim() : null,
      cardHolderName: _cardHolderController.text.trim().isNotEmpty ? _cardHolderController.text.trim() : null,
      expiryDate: _expiryController.text.trim().isNotEmpty ? _expiryController.text.trim() : null,
      cvv: _cvvController.text.trim().isNotEmpty ? _cvvController.text.trim() : null,
      cardPin: _cardPinController.text.trim().isNotEmpty ? _cardPinController.text.trim() : null,
      last4Digits: _last4Controller.text.trim().isNotEmpty ? _last4Controller.text.trim() : null,
      totalLimit: totalLimit,
      availableLimit: available,
      currentOutstanding: outstanding,
      statementDay: _statementDay,
      dueDay: _dueDay,
      colorTheme: _selectedColorTheme,
      reminderEnabled: _reminderEnabled,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: widget.existingCard?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (widget.existingCard != null) {
      success = await provider.updateCreditCard(card);
    } else {
      success = await provider.addCreditCard(card);
    }

    setState(() => _isSaving = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingCard != null ? 'Credit Card updated!' : 'Credit Card added successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save credit card.'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
