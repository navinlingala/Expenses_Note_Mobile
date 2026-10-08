import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/child_profile_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditChildProfileScreen extends StatefulWidget {
  final ChildProfileModel? child;

  const AddEditChildProfileScreen({super.key, this.child});

  @override
  State<AddEditChildProfileScreen> createState() => _AddEditChildProfileScreenState();
}

class _AddEditChildProfileScreenState extends State<AddEditChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  late TextEditingController _notesController;

  String _gender = 'MALE';
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 5));
  String _selectedAvatarColor = '0xFF3B82F6';
  bool _isSaving = false;

  final List<String> _avatarColors = [
    '0xFF3B82F6', // Blue
    '0xFFEC4899', // Pink
    '0xFF8B5CF6', // Purple
    '0xFF10B981', // Emerald
    '0xFFF59E0B', // Amber
    '0xFF06B6D4', // Cyan
    '0xFFEF4444', // Rose
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.child;
    _nameController = TextEditingController(text: c?.name ?? '');
    _schoolController = TextEditingController(text: c?.schoolOrCollege ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
    if (c != null) {
      _gender = c.gender;
      _dateOfBirth = c.dateOfBirth;
      _selectedAvatarColor = c.avatarColor;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _calculatedAgeInYears {
    final now = DateTime.now();
    int age = now.year - _dateOfBirth.year;
    if (now.month < _dateOfBirth.month ||
        (now.month == _dateOfBirth.month && now.day < _dateOfBirth.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  int get _calculatedAgeInMonths {
    final now = DateTime.now();
    int months = (now.year - _dateOfBirth.year) * 12 + now.month - _dateOfBirth.month;
    if (now.day < _dateOfBirth.day) {
      months--;
    }
    return months < 0 ? 0 : months;
  }

  String get _calculatedAgeString {
    final years = _calculatedAgeInYears;
    final months = _calculatedAgeInMonths % 12;
    if (years == 0) {
      return '$months Months';
    } else if (months == 0) {
      return '$years Years';
    } else {
      return '$years Years, $months Months';
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(int.parse(_selectedAvatarColor)),
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'default_user';

    final isEdit = widget.child != null;
    final profile = ChildProfileModel(
      id: isEdit ? widget.child!.id : const Uuid().v4(),
      userId: userId,
      name: _nameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      schoolOrCollege: _schoolController.text.trim().isEmpty ? null : _schoolController.text.trim(),
      avatarColor: _selectedAvatarColor,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: isEdit ? widget.child!.createdAt : DateTime.now(),
    );

    bool success;
    if (isEdit) {
      success = await childProvider.updateChildProfile(profile);
    } else {
      success = await childProvider.addChildProfile(profile);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Child profile updated successfully' : 'Child profile created successfully',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${childProvider.errorMessage ?? "Unknown error"}',
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
    final isEdit = widget.child != null;
    final themeColor = Color(int.parse(_selectedAvatarColor));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Child Profile' : 'Add Child Profile',
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
              // Avatar Preview Hero
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor, themeColor.withAlpha(180)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withAlpha(100),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _gender == 'FEMALE' ? Icons.face_3_rounded : Icons.face_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Avatar Color Selector
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _avatarColors.map((colorHex) {
                    final color = Color(int.parse(colorHex));
                    final isSelected = _selectedAvatarColor == colorHex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarColor = colorHex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(140),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Child Name Field
              _buildTextCard(
                label: 'Child Full Name *',
                controller: _nameController,
                hint: 'e.g. Aarav, Ananya',
                icon: Icons.person_rounded,
                isDark: isDark,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter child name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Gender Selector
              Text(
                'Gender',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption(
                      label: 'Boy',
                      value: 'MALE',
                      icon: Icons.male_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption(
                      label: 'Girl',
                      value: 'FEMALE',
                      icon: Icons.female_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date of Birth & Live Age Card
              Text(
                'Date of Birth',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cake_rounded, size: 20, color: themeColor),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_dateOfBirth),
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Age: $_calculatedAgeString',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: themeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_calendar_rounded, size: 20, color: themeColor),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // School / Grade
              _buildTextCard(
                label: 'School / Preschool / College (Optional)',
                controller: _schoolController,
                hint: 'e.g. Delhi Public School - Grade 2',
                icon: Icons.school_rounded,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Notes
              _buildTextCard(
                label: 'Notes / Medical Info (Optional)',
                controller: _notesController,
                hint: 'e.g. Blood group B+, Aspirations, Allergies',
                icon: Icons.notes_rounded,
                isDark: isDark,
                maxLines: 2,
              ),

              const SizedBox(height: 28),

              // Save CTA Button
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
                                isEdit ? 'Update Profile' : 'Save Child Profile',
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

  Widget _buildGenderOption({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _gender == value;
    final color = value == 'FEMALE' ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);

    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(isDark ? 50 : 30)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : Colors.black.withAlpha(15)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
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
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
            ),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
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
