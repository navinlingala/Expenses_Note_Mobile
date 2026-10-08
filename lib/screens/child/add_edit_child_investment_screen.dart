import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/child_investment_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditChildInvestmentScreen extends StatefulWidget {
  final ChildInvestmentModel? investment;
  final String? preselectedChildId;

  const AddEditChildInvestmentScreen({super.key, this.investment, this.preselectedChildId});

  @override
  State<AddEditChildInvestmentScreen> createState() => _AddEditChildInvestmentScreenState();
}

class _AddEditChildInvestmentScreenState extends State<AddEditChildInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _investedAmountController;
  late TextEditingController _currentValuationController;
  late TextEditingController _returnRateController;
  late TextEditingController _monthlySipController;
  late TextEditingController _folioController;
  late TextEditingController _notesController;

  String? _childId;
  String _investmentType = 'SSY';
  String _ratePeriod = 'YEARLY'; // 'YEARLY' or 'MONTHLY'
  DateTime? _startDate = DateTime.now();
  DateTime? _maturityDate;
  String _status = 'ACTIVE';
  bool _isSaving = false;

  void _switchRatePeriod(String period) {
    if (_ratePeriod == period) return;
    final currentVal = double.tryParse(_returnRateController.text.trim());
    if (currentVal != null && currentVal > 0) {
      if (period == 'MONTHLY') {
        final monthly = currentVal / 12.0;
        _returnRateController.text =
            monthly.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      } else {
        final yearly = currentVal * 12.0;
        _returnRateController.text =
            yearly.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      }
    }
    setState(() => _ratePeriod = period);
  }

  final List<Map<String, dynamic>> _investmentTypes = [
    {
      'id': 'SSY',
      'label': 'Sukanya (SSY)',
      'icon': Icons.local_florist_rounded,
      'color': const Color(0xFFEC4899),
      'defaultRate': '8.2',
    },
    {
      'id': 'MUTUAL_FUND_SIP',
      'label': 'Mutual Fund SIP',
      'icon': Icons.trending_up_rounded,
      'color': const Color(0xFF3B82F6),
      'defaultRate': '12.0',
    },
    {
      'id': 'PPF',
      'label': 'Minor PPF',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF10B981),
      'defaultRate': '7.1',
    },
    {
      'id': 'FD',
      'label': 'Child FD',
      'icon': Icons.lock_clock_rounded,
      'color': const Color(0xFFF59E0B),
      'defaultRate': '7.0',
    },
    {
      'id': 'INSURANCE',
      'label': 'Child Insurance',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF8B5CF6),
      'defaultRate': '6.5',
    },
    {
      'id': 'GOLD',
      'label': 'Gold / SGB',
      'icon': Icons.monetization_on_rounded,
      'color': const Color(0xFFEAB308),
      'defaultRate': '10.0',
    },
  ];

  @override
  void initState() {
    super.initState();
    final inv = widget.investment;
    _nameController = TextEditingController(text: inv?.investmentName ?? 'Sukanya Samriddhi Yojana');
    _investedAmountController = TextEditingController(
      text: inv != null ? inv.investedAmount.toStringAsFixed(0) : '',
    );
    _currentValuationController = TextEditingController(
      text: inv != null ? inv.currentValuation.toStringAsFixed(0) : '',
    );
    _returnRateController = TextEditingController(
      text: inv != null ? inv.expectedReturnRate.toString() : '8.2',
    );
    _monthlySipController = TextEditingController(
      text: inv != null && inv.monthlyContribution > 0 ? inv.monthlyContribution.toStringAsFixed(0) : '',
    );
    _folioController = TextEditingController(text: inv?.accountNumberOrFolio ?? '');
    _notesController = TextEditingController(text: inv?.notes ?? '');

    if (inv != null) {
      _childId = inv.childId;
      _investmentType = inv.investmentType;
      _startDate = inv.startDate;
      _maturityDate = inv.maturityDate;
      _status = inv.status;
    } else {
      _childId = widget.preselectedChildId;
      _maturityDate = DateTime.now().add(const Duration(days: 365 * 15));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _investedAmountController.dispose();
    _currentValuationController.dispose();
    _returnRateController.dispose();
    _monthlySipController.dispose();
    _folioController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeSelected(String typeId) {
    setState(() {
      _investmentType = typeId;
      final meta = _investmentTypes.firstWhere((t) => t['id'] == typeId);
      _returnRateController.text = meta['defaultRate'] as String;
      if (widget.investment == null) {
        if (typeId == 'SSY') {
          _nameController.text = 'Sukanya Samriddhi Account';
        } else if (typeId == 'MUTUAL_FUND_SIP') {
          _nameController.text = 'Child Education Fund SIP';
        } else if (typeId == 'PPF') {
          _nameController.text = 'Child PPF Account';
        } else if (typeId == 'INSURANCE') {
          _nameController.text = 'Child Future Security Plan';
        } else if (typeId == 'GOLD') {
          _nameController.text = 'Child Gold / SGB Portfolio';
        }
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_maturityDate ?? DateTime.now().add(const Duration(days: 365 * 5)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2060),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _maturityDate = picked;
        }
      });
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

    final isEdit = widget.investment != null;
    final investedAmt = double.tryParse(_investedAmountController.text.trim()) ?? 0.0;
    final currentVal = double.tryParse(_currentValuationController.text.trim()) ?? investedAmt;
    final rawRate = double.tryParse(_returnRateController.text.trim()) ?? 8.2;
    final normalizedAnnualRate = _ratePeriod == 'MONTHLY' ? rawRate * 12.0 : rawRate;

    final inv = ChildInvestmentModel(
      id: isEdit ? widget.investment!.id : const Uuid().v4(),
      childId: _childId!,
      userId: userId,
      investmentName: _nameController.text.trim(),
      investmentType: _investmentType,
      investedAmount: investedAmt,
      currentValuation: currentVal,
      expectedReturnRate: normalizedAnnualRate,
      monthlyContribution: double.tryParse(_monthlySipController.text.trim()) ?? 0.0,
      startDate: _startDate,
      maturityDate: _maturityDate,
      accountNumberOrFolio: _folioController.text.trim().isEmpty ? null : _folioController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: _status,
      createdAt: isEdit ? widget.investment!.createdAt : DateTime.now(),
    );

    bool success;
    if (isEdit) {
      success = await childProvider.updateChildInvestment(inv);
    } else {
      success = await childProvider.addChildInvestment(inv);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Investment updated successfully' : 'Child investment added successfully',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save investment: ${childProvider.errorMessage ?? "Unknown error"}',
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
    final isEdit = widget.investment != null;
    final childProvider = Provider.of<ChildProvider>(context);
    final profiles = childProvider.profiles;

    if (_childId == null && profiles.isNotEmpty) {
      _childId = profiles.first.id;
    }

    final selectedTypeMeta = _investmentTypes.firstWhere(
      (t) => t['id'] == _investmentType,
      orElse: () => _investmentTypes.first,
    );
    final themeColor = selectedTypeMeta['color'] as Color;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Child Investment' : 'Add Child Investment',
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
              // Child Selector Dropdown
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

              // Investment Type Chips
              Text(
                'Investment Instrument *',
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
                children: _investmentTypes.map((type) {
                  final isSelected = _investmentType == type['id'];
                  final col = type['color'] as Color;
                  return InkWell(
                    onTap: () => _onTypeSelected(type['id'] as String),
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
                          Icon(type['icon'] as IconData, size: 16, color: isSelected ? col : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            type['label'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
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

              // Title / Scheme Name
              _buildTextCard(
                label: 'Scheme / Plan Name *',
                controller: _nameController,
                hint: 'e.g. Post Office SSY, SBI Child Gain Plan',
                icon: Icons.badge_rounded,
                isDark: isDark,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter scheme name';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Invested Amount & Current Valuation in Responsive Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextCard(
                      label: 'Invested Amount (₹) *',
                      controller: _investedAmountController,
                      hint: '0',
                      icon: Icons.currency_rupee_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextCard(
                      label: 'Current Value (₹) *',
                      controller: _currentValuationController,
                      hint: '0',
                      icon: Icons.show_chart_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Expected Return Rate with Monthly/Yearly toggle & Monthly SIP
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _ratePeriod == 'MONTHLY' ? 'Return (%/mo)' : 'Return (% p.a.)',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _switchRatePeriod(_ratePeriod == 'YEARLY' ? 'MONTHLY' : 'YEARLY'),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: themeColor.withAlpha(isDark ? 40 : 25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _ratePeriod == 'YEARLY' ? 'to /mo' : 'to /yr',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                          ),
                          child: TextFormField(
                            controller: _returnRateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: _ratePeriod == 'MONTHLY' ? '0.7' : '8.2',
                              hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                              prefixIcon: const Icon(Icons.percent_rounded, size: 18, color: Colors.grey),
                              suffixText: _ratePeriod == 'MONTHLY' ? '%/mo' : '%/yr',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextCard(
                      label: 'Monthly SIP (₹)',
                      controller: _monthlySipController,
                      hint: 'Optional',
                      icon: Icons.savings_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Start Date & Maturity Date
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Date', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              _startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : 'Select',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: false),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withAlpha(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Maturity Date', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              _maturityDate != null ? DateFormat('dd MMM yyyy').format(_maturityDate!) : 'Select',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Folio / Policy / Account Number
              _buildTextCard(
                label: 'Account / Folio / Policy No. (Optional)',
                controller: _folioController,
                hint: 'e.g. SSY-982183921 / Policy #002819',
                icon: Icons.pin_rounded,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Notes
              _buildTextCard(
                label: 'Notes / Beneficiary Nominee (Optional)',
                controller: _notesController,
                hint: 'e.g. 80C tax deduction, lock-in period 15 years',
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
                                isEdit ? 'Update Investment' : 'Save Child Investment',
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
