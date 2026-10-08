import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vault_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';

class AddEditVaultItemScreen extends StatefulWidget {
  final VaultItemModel? existingItem;
  final String? initialType; // CARD, BANK_ACCOUNT, PASSWORD_PIN, SECRET_NOTE

  const AddEditVaultItemScreen({
    super.key,
    this.existingItem,
    this.initialType,
  });

  @override
  State<AddEditVaultItemScreen> createState() => _AddEditVaultItemScreenState();
}

class _AddEditVaultItemScreenState extends State<AddEditVaultItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _numberController;
  late TextEditingController _holderController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _pinController;
  late TextEditingController _passwordController;
  late TextEditingController _ifscController;
  late TextEditingController _upiController;
  late TextEditingController _urlController;
  late TextEditingController _secretContentController;
  late TextEditingController _notesController;

  String _colorTheme = 'OBSIDIAN';
  String _category = 'GENERAL';
  bool _isFavorite = false;
  bool _isSaving = false;
  bool _showPassword = false;
  bool _showPin = false;
  bool _showCvv = false;

  final Map<String, List<Color>> _themePresets = {
    'OBSIDIAN': [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
    'BLUE_PURPLE': [const Color(0xFF312E81), const Color(0xFF4338CA), const Color(0xFF7C3AED)],
    'EMERALD': [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF10B981)],
    'CRIMSON': [const Color(0xFF881337), const Color(0xFFBE123C), const Color(0xFFE11D48)],
    'GOLD': [const Color(0xFF78350F), const Color(0xFFB45309), const Color(0xFFF59E0B)],
    'OCEAN': [const Color(0xFF0C4A6E), const Color(0xFF0284C7), const Color(0xFF38BDF8)],
    'AMETHYST': [const Color(0xFF4C1D95), const Color(0xFF6D28D9), const Color(0xFFA855F7)],
  };

  final List<String> _popularBanks = [
    'HDFC Bank', 'SBI', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra',
    'Bank of Baroda', 'Punjab National Bank', 'Canara Bank', 'IndusInd Bank', 'IDFC FIRST'
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _selectedType = item?.itemType ?? widget.initialType ?? 'CARD';

    _titleController = TextEditingController(text: item?.title ?? '');
    _subtitleController = TextEditingController(text: item?.subtitle ?? '');
    _numberController = TextEditingController(text: item?.accountOrCardNumber ?? '');
    _holderController = TextEditingController(text: item?.holderName ?? '');
    _expiryController = TextEditingController(text: item?.expiryDate ?? '');
    _cvvController = TextEditingController(text: item?.cvv ?? '');
    _pinController = TextEditingController(text: item?.pin ?? '');
    _passwordController = TextEditingController(text: item?.password ?? '');
    _ifscController = TextEditingController(text: item?.ifscCode ?? '');
    _upiController = TextEditingController(text: item?.upiId ?? '');
    _urlController = TextEditingController(text: item?.urlOrApp ?? '');
    _secretContentController = TextEditingController(text: item?.secretContent ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    if (item != null) {
      _colorTheme = item.colorTheme;
      _category = item.category;
      _isFavorite = item.isFavorite;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _pinController.dispose();
    _passwordController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    _urlController.dispose();
    _secretContentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generateStrongPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()-_=+';
    final random = Random.secure();
    final pass = List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = pass;
      _showPassword = true;
    });
  }

  void _formatCardNumber(String value) {
    String clean = value.replaceAll(RegExp(r'\s+'), '');
    if (clean.length > 19) clean = clean.substring(0, 19);

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    final formatted = buffer.toString();
    if (_numberController.text != formatted) {
      _numberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
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
    final isEditing = widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vault Item' : 'Add to Secure Vault'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: _isFavorite ? const Color(0xFFFBBF24) : null),
            tooltip: 'Favorite',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
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
              if (!isEditing) ...[
                _buildTypeSelector(isDark),
                const SizedBox(height: 20),
              ],

              // LIVE PREVIEW BANNER
              _buildLivePreview(isDark),
              const SizedBox(height: 20),

              // DYNAMIC FORM FIELDS
              if (_selectedType == 'CARD') _buildCardFields(isDark),
              if (_selectedType == 'BANK_ACCOUNT') _buildBankAccountFields(isDark),
              if (_selectedType == 'PASSWORD_PIN') _buildPasswordFields(isDark),
              if (_selectedType == 'SECRET_NOTE') _buildSecretNoteFields(isDark),

              const SizedBox(height: 16),
              _buildSectionTitle('CONFIDENTIAL NOTES / EXTRA DETAILS'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Secret Notes (Optional)',
                  hintText: 'Security questions, locker combination, branch phone',
                  prefixIcon: Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveVaultItem,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.security_rounded),
                  label: Text(
                    isEditing ? 'Update in Secure Vault' : 'Save to Secure Vault',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    final types = [
      {'key': 'CARD', 'label': 'Cards', 'icon': Icons.credit_card_rounded},
      {'key': 'BANK_ACCOUNT', 'label': 'Bank Acc', 'icon': Icons.account_balance_rounded},
      {'key': 'PASSWORD_PIN', 'label': 'PIN & Pass', 'icon': Icons.vpn_key_rounded},
      {'key': 'SECRET_NOTE', 'label': 'Secret Note', 'icon': Icons.security_rounded},
    ];

    return Row(
      children: types.map((t) {
        final isSelected = _selectedType == t['key'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _selectedType = t['key'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF1E293B) : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLivePreview(bool isDark) {
    final gradients = _themePresets[_colorTheme] ?? _themePresets['OBSIDIAN']!;
    final title = _titleController.text.trim().isEmpty ? 'Secret Item' : _titleController.text.trim();
    final subtitle = _subtitleController.text.trim().isEmpty ? '' : _subtitleController.text.trim();
    final number = _numberController.text.trim().isEmpty ? '•••• •••• •••• ••••' : _numberController.text.trim();
    final holder = _holderController.text.trim().isEmpty ? 'ACCOUNT HOLDER' : _holderController.text.trim();

    return Container(
      height: 175,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradients.first.withAlpha(isDark ? 90 : 120),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle.toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      _selectedType,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_selectedType == 'CARD') ...[
            Row(
              children: [
                Container(
                  width: 30,
                  height: 22,
                  decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.credit_card, size: 14, color: Colors.black54),
                ),
                const SizedBox(width: 10),
                Text(
                  number,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontFamily: 'monospace'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(holder.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(_expiryController.text.isNotEmpty ? 'EXP: ${_expiryController.text}' : 'MM/YY', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                if (_cvvController.text.isNotEmpty)
                  Text('CVV: ${_showCvv ? _cvvController.text : "•••"}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ] else if (_selectedType == 'BANK_ACCOUNT') ...[
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  'A/C: $number',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(holder.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                if (_ifscController.text.isNotEmpty)
                  Text('IFSC: ${_ifscController.text}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ] else if (_selectedType == 'PASSWORD_PIN') ...[
            Row(
              children: [
                const Icon(Icons.lock_person_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  _holderController.text.isNotEmpty ? _holderController.text : 'username@email.com',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_showPassword ? (_passwordController.text.isNotEmpty ? _passwordController.text : '••••••••') : '••••••••••••', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                if (_pinController.text.isNotEmpty)
                  Text('PIN: ${_showPin ? _pinController.text : "••••"}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ] else ...[
            const Icon(Icons.shield_rounded, color: Colors.white70, size: 28),
            Text(
              _secretContentController.text.isNotEmpty ? 'Encrypted Secure Note Content Stored' : 'Enter secret information below',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== CARD FIELDS =====================
  Widget _buildCardFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CARD DETAILS'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Card Nickname / Name *',
            hintText: 'e.g. HDFC Regalia, ICICI Amazon, SBI Prime',
            prefixIcon: Icon(Icons.credit_card_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter card name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _subtitleController,
          decoration: const InputDecoration(
            labelText: 'Bank Name',
            hintText: 'e.g. HDFC Bank, SBI, ICICI',
            prefixIcon: Icon(Icons.account_balance_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Card Number (16 Digits) *',
            hintText: '4532 8901 2345 6789',
            prefixIcon: Icon(Icons.payment_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: _formatCardNumber,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter card number' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _holderController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Card Holder Name',
            hintText: 'e.g. NAVEEN KUMAR',
            prefixIcon: Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: const InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  hintText: '08/29',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onChanged: _formatExpiry,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
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
              child: TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: !_showPin,
                decoration: InputDecoration(
                  labelText: 'ATM PIN',
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
        const SizedBox(height: 16),
        _buildSectionTitle('COLOR THEME'),
        const SizedBox(height: 8),
        _buildThemeSelector(),
      ],
    );
  }

  // ===================== BANK ACCOUNT FIELDS =====================
  Widget _buildBankAccountFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('BANK ACCOUNT DETAILS'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Bank Name / Account Title *',
            hintText: 'e.g. HDFC Salary Account, SBI Savings',
            prefixIcon: Icon(Icons.account_balance_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _subtitleController,
          decoration: const InputDecoration(
            labelText: 'Branch / Account Type',
            hintText: 'e.g. Main Branch, Savings, Current',
            prefixIcon: Icon(Icons.business_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Account Number *',
            hintText: 'e.g. 50100234567890',
            prefixIcon: Icon(Icons.numbers_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter account number' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _holderController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Account Holder Name',
            hintText: 'e.g. NAVEEN KUMAR',
            prefixIcon: Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  hintText: 'HDFC0001234',
                  prefixIcon: Icon(Icons.qr_code_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _upiController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'name@oksbi',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: !_showPin,
          decoration: InputDecoration(
            labelText: 'UPI / NetBanking Security PIN',
            hintText: '••••',
            prefixIcon: const Icon(Icons.pin_rounded),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
              onPressed: () => setState(() => _showPin = !_showPin),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== PASSWORD / PIN FIELDS =====================
  Widget _buildPasswordFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('LOGIN / APP CREDENTIALS'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title / Service Name *',
            hintText: 'e.g. Google Workspace, Zerodha Kite, WiFi',
            prefixIcon: Icon(Icons.vpn_key_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _holderController,
          decoration: const InputDecoration(
            labelText: 'Username / Email / Mobile *',
            hintText: 'e.g. naveen@gmail.com or 9876543210',
            prefixIcon: Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username or email' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '••••••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF6366F1), size: 18),
                  tooltip: 'Generate Strong Password',
                  onPressed: _generateStrongPassword,
                ),
                IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ],
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pinController,
                obscureText: !_showPin,
                decoration: InputDecoration(
                  labelText: 'Security PIN / 2FA Note',
                  hintText: '••••',
                  prefixIcon: const Icon(Icons.pin_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                    onPressed: () => setState(() => _showPin = !_showPin),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Website / App URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================== SECRET NOTE FIELDS =====================
  Widget _buildSecretNoteFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CONFIDENTIAL SECRET NOTE'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Note Title *',
            hintText: 'e.g. Home Locker Master Code, Aadhaar/PAN details',
            prefixIcon: Icon(Icons.security_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _subtitleController,
          decoration: const InputDecoration(
            labelText: 'Category / Tag',
            hintText: 'e.g. Locker, Identity, Policy, Crypto, Keys',
            prefixIcon: Icon(Icons.category_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _secretContentController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Secret Confidential Content *',
            hintText: 'Write confidential recovery codes, secret numbers, key combinations here...',
            prefixIcon: Icon(Icons.lock_rounded),
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter secret content' : null,
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _themePresets.entries.map((entry) {
          final isSelected = _colorTheme == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _colorTheme = entry.key),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 36,
              height: 36,
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
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveVaultItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'guest_user';
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

    final item = VaultItemModel(
      id: widget.existingItem?.id ?? '',
      userId: userId,
      itemType: _selectedType,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isNotEmpty ? _subtitleController.text.trim() : null,
      accountOrCardNumber: _numberController.text.trim().isNotEmpty ? _numberController.text.trim() : null,
      holderName: _holderController.text.trim().isNotEmpty ? _holderController.text.trim() : null,
      expiryDate: _expiryController.text.trim().isNotEmpty ? _expiryController.text.trim() : null,
      cvv: _cvvController.text.trim().isNotEmpty ? _cvvController.text.trim() : null,
      pin: _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : null,
      password: _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null,
      ifscCode: _ifscController.text.trim().isNotEmpty ? _ifscController.text.trim() : null,
      upiId: _upiController.text.trim().isNotEmpty ? _upiController.text.trim() : null,
      urlOrApp: _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null,
      secretContent: _secretContentController.text.trim().isNotEmpty ? _secretContentController.text.trim() : null,
      colorTheme: _colorTheme,
      category: _category,
      isFavorite: _isFavorite,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (widget.existingItem != null) {
      success = await vaultProvider.updateVaultItem(item);
    } else {
      success = await vaultProvider.addVaultItem(item);
    }

    setState(() => _isSaving = false);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingItem != null ? 'Vault item updated securely!' : 'Item saved to Secure Vault!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save to vault.'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
