import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gold_asset_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gold_provider.dart';

class AddEditGoldAssetScreen extends StatefulWidget {
  final GoldAssetModel? assetToEdit;

  const AddEditGoldAssetScreen({super.key, this.assetToEdit});

  @override
  State<AddEditGoldAssetScreen> createState() => _AddEditGoldAssetScreenState();
}

class _AddEditGoldAssetScreenState extends State<AddEditGoldAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _weightGramsCtrl;
  late TextEditingController _weightTolasCtrl;
  late TextEditingController _pricePerGramCtrl;
  late TextEditingController _makingChargesCtrl;
  late TextEditingController _lockerLocationCtrl;
  late TextEditingController _huidCtrl;
  late TextEditingController _jewelerCtrl;
  late TextEditingController _sgbRateCtrl;
  late TextEditingController _notesCtrl;

  late GoldType _selectedType;
  late GoldPurity _selectedPurity;
  late DateTime _purchaseDate;
  DateTime? _maturityDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final asset = widget.assetToEdit;

    _titleCtrl = TextEditingController(text: asset?.title ?? '');
    _weightGramsCtrl = TextEditingController(
      text: asset != null ? asset.weightInGrams.toStringAsFixed(asset.weightInGrams.truncateToDouble() == asset.weightInGrams ? 0 : 2) : '',
    );
    _weightTolasCtrl = TextEditingController(
      text: asset != null ? asset.weightInTolas.toStringAsFixed(2) : '',
    );
    _pricePerGramCtrl = TextEditingController(
      text: asset != null ? asset.purchasePricePerGram.toStringAsFixed(0) : '',
    );
    _makingChargesCtrl = TextEditingController(
      text: asset != null && asset.makingCharges > 0 ? asset.makingCharges.toStringAsFixed(0) : '',
    );
    _lockerLocationCtrl = TextEditingController(text: asset?.lockerLocation ?? '');
    _huidCtrl = TextEditingController(text: asset?.huidNumber ?? '');
    _jewelerCtrl = TextEditingController(text: asset?.jewelerName ?? '');
    _sgbRateCtrl = TextEditingController(
      text: (asset?.sgbInterestRate ?? 2.50).toStringAsFixed(2),
    );
    _notesCtrl = TextEditingController(text: asset?.notes ?? '');

    _selectedType = asset?.typeEnum ?? GoldType.jewelry;
    _selectedPurity = asset?.purityEnum ?? GoldPurity.k22;
    _purchaseDate = asset?.purchaseDate ?? DateTime.now();
    _maturityDate = asset?.maturityDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _weightGramsCtrl.dispose();
    _weightTolasCtrl.dispose();
    _pricePerGramCtrl.dispose();
    _makingChargesCtrl.dispose();
    _lockerLocationCtrl.dispose();
    _huidCtrl.dispose();
    _jewelerCtrl.dispose();
    _sgbRateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onGramsChanged(String val) {
    final grams = double.tryParse(val.trim());
    if (grams != null && grams > 0) {
      _weightTolasCtrl.text = (grams / 10.0).toStringAsFixed(2);
    } else {
      _weightTolasCtrl.text = '';
    }
    setState(() {});
  }

  void _onTolasChanged(String val) {
    final tolas = double.tryParse(val.trim());
    if (tolas != null && tolas > 0) {
      _weightGramsCtrl.text = (tolas * 10.0).toStringAsFixed(2);
    } else {
      _weightGramsCtrl.text = '';
    }
    setState(() {});
  }

  double get _calculatedTotalInvested {
    final grams = double.tryParse(_weightGramsCtrl.text.trim()) ?? 0.0;
    final rate = double.tryParse(_pricePerGramCtrl.text.trim()) ?? 0.0;
    final making = double.tryParse(_makingChargesCtrl.text.trim()) ?? 0.0;
    return (grams * rate) + making;
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _pickMaturityDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _maturityDate ?? DateTime.now().add(const Duration(days: 365 * 8)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() => _maturityDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final grams = double.tryParse(_weightGramsCtrl.text.trim()) ?? 0.0;
    final pricePerGram = double.tryParse(_pricePerGramCtrl.text.trim()) ?? 0.0;
    final makingCharges = double.tryParse(_makingChargesCtrl.text.trim()) ?? 0.0;
    final sgbRate = double.tryParse(_sgbRateCtrl.text.trim()) ?? 2.50;

    if (grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid gold weight in grams.')),
      );
      return;
    }

    if (pricePerGram <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid purchase rate per gram.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest_user';
    final totalInvested = (grams * pricePerGram) + makingCharges;

    final asset = GoldAssetModel(
      id: widget.assetToEdit?.id ?? '',
      userId: userId,
      title: _titleCtrl.text.trim(),
      goldType: _selectedType.code,
      purity: _selectedPurity.code,
      weightInGrams: grams,
      purchasePricePerGram: pricePerGram,
      makingCharges: makingCharges,
      totalInvestedAmount: totalInvested,
      purchaseDate: _purchaseDate,
      lockerLocation: _lockerLocationCtrl.text.trim().isEmpty ? null : _lockerLocationCtrl.text.trim(),
      huidNumber: _huidCtrl.text.trim().isEmpty ? null : _huidCtrl.text.trim(),
      jewelerName: _jewelerCtrl.text.trim().isEmpty ? null : _jewelerCtrl.text.trim(),
      sgbInterestRate: sgbRate,
      maturityDate: _selectedType == GoldType.sgb ? _maturityDate : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      status: widget.assetToEdit?.status ?? 'ACTIVE',
    );

    final provider = context.read<GoldProvider>();
    bool success;
    if (widget.assetToEdit == null) {
      success = await provider.addGoldAsset(asset);
    } else {
      success = await provider.updateGoldAsset(asset);
    }

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.assetToEdit == null
                ? 'Gold asset saved successfully!'
                : 'Gold asset updated successfully!',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.creditGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save gold asset.'),
          backgroundColor: AppTheme.debitRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.assetToEdit != null;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Gold Asset' : 'Add Gold Asset',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Asset Type Selector
              Text(
                'Gold Asset Type',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEAB308)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: GoldType.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final type = GoldType.values[idx];
                    final isSel = _selectedType == type;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                          if (type == GoldType.sgb || type == GoldType.coin || type == GoldType.bar) {
                            _selectedPurity = GoldPurity.k24;
                          } else if (type == GoldType.jewelry) {
                            _selectedPurity = GoldPurity.k22;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFFEAB308).withAlpha(isDark ? 50 : 25)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? const Color(0xFFEAB308) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(type.icon, size: 16, color: isSel ? const Color(0xFFEAB308) : (isDark ? Colors.white60 : Colors.black54)),
                            const SizedBox(width: 6),
                            Text(
                              type.displayName.split(' / ')[0].split(' (')[0],
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? const Color(0xFFEAB308) : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 2. Title Field
              _buildTextCard(
                label: 'Asset Title / Name *',
                hint: 'e.g. 22K Traditional Necklace, SGB 2023 Series IV',
                controller: _titleCtrl,
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                icon: Icons.label_outline_rounded,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // 3. Purity Selector
              Text(
                'Gold Purity',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final purity in GoldPurity.values)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPurity = purity),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedPurity == purity
                                ? const Color(0xFFF59E0B)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPurity == purity ? const Color(0xFFF59E0B) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                purity.shortName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedPurity == purity ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              Text(
                                purity == GoldPurity.k24
                                    ? '99.9%'
                                    : purity == GoldPurity.k22
                                        ? '91.6%'
                                        : purity == GoldPurity.k18
                                            ? '75.0%'
                                            : '58.5%',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedPurity == purity ? Colors.white70 : (isDark ? Colors.white38 : Colors.black45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Weight in Grams & Tolas Live Converter
              Row(
                children: [
                  Expanded(
                    child: _buildTextCard(
                      label: 'Weight (Grams) *',
                      hint: 'e.g. 24.50',
                      controller: _weightGramsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.scale_rounded,
                      isDark: isDark,
                      onChanged: _onGramsChanged,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter weight' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextCard(
                      label: 'Weight (Tolas)',
                      hint: 'e.g. 2.45',
                      controller: _weightTolasCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.calculate_outlined,
                      isDark: isDark,
                      onChanged: _onTolasChanged,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 5. Purchase Rate & Making Charges
              Row(
                children: [
                  Expanded(
                    child: _buildTextCard(
                      label: 'Buy Rate / Gram (₹) *',
                      hint: 'e.g. 6400',
                      controller: _pricePerGramCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.currency_rupee_rounded,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter buy rate' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextCard(
                      label: 'Making / Wastage (₹)',
                      hint: 'Optional e.g. 3500',
                      controller: _makingChargesCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.add_circle_outline_rounded,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Total Cost Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308).withAlpha(isDark ? 25 : 18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEAB308).withAlpha(80)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFFEAB308)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Total Purchase Cost:',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹ ${NumberFormat('#,##,##0').format(_calculatedTotalInvested)}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFEAB308),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6. Purchase Date & SGB Maturity Date
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickPurchaseDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase Date',
                              style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_purchaseDate),
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedType == GoldType.sgb) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickMaturityDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SGB Maturity Date',
                                style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 16, color: AppTheme.creditGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    _maturityDate != null ? DateFormat('dd MMM yyyy').format(_maturityDate!) : 'Select Date',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              if (_selectedType == GoldType.sgb) ...[
                const SizedBox(height: 14),
                _buildTextCard(
                  label: 'SGB Annual Interest Rate (%)',
                  hint: 'Default 2.50%',
                  controller: _sgbRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.percent_rounded,
                  isDark: isDark,
                ),
              ],

              const SizedBox(height: 14),

              // 7. Safety, Locker & Hallmarking Details
              Text(
                'Safety & Locker Vault Information',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextCard(
                      label: 'Locker Location / Bank',
                      hint: 'e.g. SBI Locker #42, Home Safe',
                      controller: _lockerLocationCtrl,
                      icon: Icons.lock_clock_outlined,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextCard(
                      label: 'HUID / Hallmark No.',
                      hint: 'e.g. AB1234',
                      controller: _huidCtrl,
                      icon: Icons.verified_outlined,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _buildTextCard(
                label: 'Jeweler / Platform Name',
                hint: 'e.g. Tanishq, Malabar, Kalyan, Augmont',
                controller: _jewelerCtrl,
                icon: Icons.storefront_outlined,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              _buildTextCard(
                label: 'Additional Notes / Bill Info',
                hint: 'Invoice details, occasion, or gift notes',
                controller: _notesCtrl,
                icon: Icons.notes_rounded,
                maxLines: 2,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // 8. Submit CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAB308),
                    foregroundColor: Colors.black,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isEdit ? Icons.check_circle_rounded : Icons.add_circle_rounded, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEdit ? 'Update Gold Asset' : 'Save Gold Asset',
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
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: validator,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
