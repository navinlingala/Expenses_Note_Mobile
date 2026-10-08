import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/child_future_goal_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditChildGoalScreen extends StatefulWidget {
  final ChildFutureGoalModel? goal;
  final String? preselectedChildId;

  const AddEditChildGoalScreen({super.key, this.goal, this.preselectedChildId});

  @override
  State<AddEditChildGoalScreen> createState() => _AddEditChildGoalScreenState();
}

class _AddEditChildGoalScreenState extends State<AddEditChildGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late TextEditingController _inflationRateController;
  late TextEditingController _targetYearController;
  late TextEditingController _notesController;

  String? _childId;
  bool _isSaving = false;

  final List<String> _popularGoalSuggestions = [
    '🎓 Engineering College Fund (Age 18)',
    '🩺 MBBS Medical Degree Fund (Age 18)',
    '🌍 Foreign Masters Degree (Age 22)',
    '💼 Startup Launchpad / Business (Age 24)',
    '💍 Marriage / Future Milestone (Age 25)',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleController = TextEditingController(text: g?.goalTitle ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? g.targetAmountToday.toStringAsFixed(0) : '2000000',
    );
    _inflationRateController = TextEditingController(
      text: g != null ? g.estimatedInflationRate.toString() : '8.0',
    );
    _targetYearController = TextEditingController(
      text: g != null ? g.targetYear.toString() : (DateTime.now().year + 12).toString(),
    );
    _notesController = TextEditingController(text: g?.notes ?? '');
    _childId = g?.childId ?? widget.preselectedChildId;

    _targetAmountController.addListener(() => setState(() {}));
    _inflationRateController.addListener(() => setState(() {}));
    _targetYearController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _inflationRateController.dispose();
    _targetYearController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _targetAmount => double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
  double get _inflationRate => double.tryParse(_inflationRateController.text.trim()) ?? 8.0;
  int get _targetYear => int.tryParse(_targetYearController.text.trim()) ?? (DateTime.now().year + 10);

  ChildFutureGoalModel get _tempGoal => ChildFutureGoalModel(
        id: 'temp',
        childId: _childId ?? '',
        userId: 'temp',
        goalTitle: _titleController.text,
        targetAmountToday: _targetAmount,
        estimatedInflationRate: _inflationRate,
        targetYear: _targetYear,
      );

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

    final isEdit = widget.goal != null;
    final goalModel = ChildFutureGoalModel(
      id: isEdit ? widget.goal!.id : const Uuid().v4(),
      childId: _childId!,
      userId: userId,
      goalTitle: _titleController.text.trim(),
      targetAmountToday: _targetAmount,
      estimatedInflationRate: _inflationRate,
      targetYear: _targetYear,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: isEdit ? widget.goal!.createdAt : DateTime.now(),
    );

    bool success;
    if (isEdit) {
      success = await childProvider.updateChildFutureGoal(goalModel);
    } else {
      success = await childProvider.addChildFutureGoal(goalModel);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Goal updated successfully' : 'Future education goal created successfully',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal: ${childProvider.errorMessage ?? "Unknown error"}',
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
    final isEdit = widget.goal != null;
    final childProvider = Provider.of<ChildProvider>(context);
    final profiles = childProvider.profiles;

    if (_childId == null && profiles.isNotEmpty) {
      _childId = profiles.first.id;
    }

    final futureCost = _tempGoal.estimatedFutureCost;
    final yearsLeft = _tempGoal.yearsRemaining;
    final suggestedMonthlySip = _tempGoal.calculateSuggestedMonthlySip(
      currentAccumulated: childProvider.totalCurrentValuation,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Future Goal' : 'Add Future Goal',
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

              // Popular Goal Suggestions Chips
              Text(
                'Quick Goal Templates',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularGoalSuggestions.map((template) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          template,
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onPressed: () {
                          setState(() {
                            _titleController.text = template;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Goal Title
              _buildTextCard(
                label: 'Goal Title / Target Degree *',
                controller: _titleController,
                hint: 'e.g. Higher Education Fund, College Tuition',
                icon: Icons.flag_rounded,
                isDark: isDark,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter goal title';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Target Amount Today & Inflation Rate Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextCard(
                      label: "Today's Cost (₹) *",
                      controller: _targetAmountController,
                      hint: '20,00,000',
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
                      label: 'Education Inflation (%)',
                      controller: _inflationRateController,
                      hint: '8.0',
                      icon: Icons.trending_up_rounded,
                      isDark: isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Target Year
              _buildTextCard(
                label: 'Target Year (e.g. 2038) *',
                controller: _targetYearController,
                hint: (DateTime.now().year + 12).toString(),
                icon: Icons.calendar_today_rounded,
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  final y = int.tryParse(val.trim());
                  if (y == null || y <= DateTime.now().year) return 'Must be future year';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Live Inflation Projection Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A8A), const Color(0xFF312E81)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFEEF2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withAlpha(isDark ? 80 : 50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF3B82F6), size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'SMART INFLATION PROJECTION',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$yearsLeft Years to Go',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Future Cost in $_targetYear:',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹ ${NumberFormat('#,##,##0').format(futureCost)}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Suggested Monthly SIP:',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹ ${NumberFormat('#,##,##0').format(suggestedMonthlySip)}/mo',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* Assumes $_inflationRate% annual education inflation and 12% equity mutual fund returns.',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notes
              _buildTextCard(
                label: 'Notes / Target College / Notes (Optional)',
                controller: _notesController,
                hint: 'e.g. Target IIT Madras, Stanford, AIIMS',
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
                    backgroundColor: const Color(0xFF3B82F6),
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
                                isEdit ? 'Update Goal' : 'Save Future Goal',
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
