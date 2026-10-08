import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/child_profile_model.dart';
import '../../models/child_expense_model.dart';
import '../../models/child_investment_model.dart';
import '../../models/child_future_goal_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_edit_child_profile_screen.dart';
import 'add_edit_child_expense_screen.dart';
import 'add_edit_child_investment_screen.dart';
import 'add_edit_child_goal_screen.dart';

class ChildHubScreen extends StatefulWidget {
  const ChildHubScreen({super.key});

  @override
  State<ChildHubScreen> createState() => _ChildHubScreenState();
}

class _ChildHubScreenState extends State<ChildHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id ?? 'default_user';
      Provider.of<ChildProvider>(context, listen: false).loadChildData(userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final selectedChildId = childProvider.selectedChildId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quick Add Options',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Record Child Expense',
                    subtitle: 'School fees, doctor, clothes, toys',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditChildExpenseScreen(preselectedChildId: selectedChildId),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Add Child Investment',
                    subtitle: 'Sukanya Samriddhi (SSY), SIPs, Gold, Insurance',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditChildInvestmentScreen(preselectedChildId: selectedChildId),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.flag_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Plan Future Education Goal',
                    subtitle: 'Target college fund with inflation calculation',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditChildGoalScreen(preselectedChildId: selectedChildId),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.person_add_alt_1_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Add New Child Profile',
                    subtitle: 'Register profile with birthdate & school',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditChildProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final childProvider = Provider.of<ChildProvider>(context);
    final profiles = childProvider.profiles;
    final selectedChild = childProvider.selectedChild;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withAlpha(50)),
              ),
              child: const Icon(Icons.child_care_rounded, color: Color(0xFF3B82F6), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kids Wealth & Care',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(
                    'Expenses, SSY & Future Goals',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_add_rounded, size: 20, color: Color(0xFF3B82F6)),
              tooltip: 'Add Child Profile',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditChildProfileScreen()),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
              onPressed: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                childProvider.loadChildData(auth.currentUser?.id ?? 'default_user');
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActionSheet(context),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          '+ Add',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      body: childProvider.isLoading && profiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Child Profile Selector Bar
                  _buildChildSelectorBar(context, childProvider, isDark),

                  const SizedBox(height: 14),

                  // Grand Wealth & Spend Summary Card
                  _buildGrandSummaryCard(context, childProvider, selectedChild, isDark),

                  const SizedBox(height: 16),

                  // Segmented Tabs Header
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF3B82F6),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF3B82F6),
                      unselectedLabelColor: Colors.grey,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Expenses'),
                        Tab(icon: Icon(Icons.trending_up_rounded, size: 18), text: 'Investments'),
                        Tab(icon: Icon(Icons.flag_rounded, size: 18), text: 'Goals'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tab Views in dynamic height container
                  SizedBox(
                    height: 540,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExpensesTab(context, childProvider, isDark),
                        _buildInvestmentsTab(context, childProvider, isDark),
                        _buildGoalsTab(context, childProvider, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChildSelectorBar(BuildContext context, ChildProvider provider, bool isDark) {
    final profiles = provider.profiles;
    final selectedId = provider.selectedChildId;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Children Pill
          InkWell(
            onTap: () => provider.selectChild(null),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: selectedId == null
                    ? const Color(0xFF3B82F6)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedId == null ? const Color(0xFF3B82F6) : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: selectedId == null ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Kids (${profiles.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: selectedId == null ? FontWeight.w800 : FontWeight.w600,
                      color: selectedId == null ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Individual Child Profile Pills
          ...profiles.map((p) {
            final isSelected = selectedId == p.id;
            final childColor = Color(int.parse(p.avatarColor));
            return InkWell(
              onTap: () => provider.selectChild(p.id),
              onLongPress: () => _showChildOptionsModal(context, p),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? childColor.withAlpha(isDark ? 60 : 35)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? childColor : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: childColor,
                      child: Icon(
                        p.gender == 'FEMALE' ? Icons.face_3_rounded : Icons.face_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? childColor : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          p.formattedAge,
                          style: GoogleFonts.outfit(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          // Add Child Button
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditChildProfileScreen()),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withAlpha(80), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 4),
                  Text(
                    'Add Child',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChildOptionsModal(BuildContext context, ChildProfileModel profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
                title: Text('Edit ${profile.name}\'s Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditChildProfileScreen(child: profile)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: Text('Delete ${profile.name}\'s Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: Text('Delete ${profile.name}?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      content: Text(
                        'This will delete this child profile along with all their linked expenses, investments, and goals.',
                        style: GoogleFonts.outfit(),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    Provider.of<ChildProvider>(context, listen: false).deleteChildProfile(profile.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrandSummaryCard(
    BuildContext context,
    ChildProvider provider,
    ChildProfileModel? selectedChild,
    bool isDark,
  ) {
    final monthlyExpense = provider.totalMonthlyChildExpenses;
    final totalInvested = provider.totalCurrentValuation;
    final monthlySip = provider.totalMonthlySipCommitment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(80),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
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
                    const Icon(Icons.auto_graph_rounded, color: Colors.lightBlueAccent, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        selectedChild != null ? '${selectedChild.name.toUpperCase()} FINANCE' : 'TOTAL KIDS PORTFOLIO',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white70,
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
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.lightBlueAccent.withAlpha(100)),
                ),
                child: Text(
                  selectedChild != null ? selectedChild.formattedAge : '${provider.profiles.length} Kids',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                '₹${NumberFormat('#,##,##0').format(totalInvested)}',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Future Wealth',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month Spend',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,##0').format(monthlyExpense)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly SIPs',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,##0').format(monthlySip)}/mo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.lightGreenAccent,
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

  // --- Expenses Tab ---
  Widget _buildExpensesTab(BuildContext context, ChildProvider provider, bool isDark) {
    final expenses = provider.filteredExpenses;
    final categories = [
      {'id': 'ALL', 'label': 'All'},
      {'id': 'EDUCATION', 'label': 'School & Fees'},
      {'id': 'HEALTHCARE', 'label': 'Medical'},
      {'id': 'CHILDCARE', 'label': 'Toys & Care'},
      {'id': 'EVENTS', 'label': 'Events'},
      {'id': 'ALLOWANCE', 'label': 'Pocket Money'},
    ];

    return Column(
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSel = provider.selectedExpenseCategory == cat['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat['label']!, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: const Color(0xFF3B82F6).withAlpha(50),
                  onSelected: (_) => provider.selectExpenseCategory(cat['id']!),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Expense List
        Expanded(
          child: expenses.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No Child Expenses Recorded',
                  subtitle: 'Start tracking school fees, pediatric bills, toys, and activities.',
                  buttonLabel: '+ Record Expense',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditChildExpenseScreen(preselectedChildId: provider.selectedChildId),
                    ),
                  ),
                  isDark: isDark,
                )
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    return _buildExpenseCard(context, exp, provider, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(BuildContext context, ChildExpenseModel exp, ChildProvider provider, bool isDark) {
    IconData icon;
    Color color;

    switch (exp.category) {
      case 'EDUCATION':
        icon = Icons.school_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'HEALTHCARE':
        icon = Icons.medical_services_rounded;
        color = const Color(0xFFEF4444);
        break;
      case 'CHILDCARE':
        icon = Icons.toys_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'EVENTS':
        icon = Icons.celebration_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'ALLOWANCE':
        icon = Icons.savings_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      default:
        icon = Icons.category_rounded;
        color = const Color(0xFF6B7280);
    }

    ChildProfileModel? child;
    try {
      child = provider.profiles.firstWhere((p) => p.id == exp.childId);
    } catch (_) {}

    return Dismissible(
      key: Key(exp.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text('Delete Expense?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text('Are you sure you want to delete "${exp.title}"?', style: GoogleFonts.outfit()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(dCtx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteChildExpense(exp.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditChildExpenseScreen(expense: exp)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              exp.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (child != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Color(int.parse(child.avatarColor)).withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                child.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(int.parse(child.avatarColor)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(exp.expenseDate),
                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                          ),
                          if (exp.isRecurring) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                exp.recurrenceFrequency,
                                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${NumberFormat('#,##,##0').format(exp.amount)}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Investments Tab ---
  Widget _buildInvestmentsTab(BuildContext context, ChildProvider provider, bool isDark) {
    final investments = provider.filteredInvestments;

    return investments.isEmpty
        ? _buildEmptyState(
            icon: Icons.trending_up_rounded,
            title: 'No Child Investments Found',
            subtitle: 'Add Sukanya Samriddhi (SSY 8.2%), Child Education SIPs, or Insurance.',
            buttonLabel: '+ Add Investment',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditChildInvestmentScreen(preselectedChildId: provider.selectedChildId),
              ),
            ),
            isDark: isDark,
          )
        : ListView.builder(
            itemCount: investments.length,
            itemBuilder: (context, index) {
              final inv = investments[index];
              return _buildInvestmentCard(context, inv, provider, isDark);
            },
          );
  }

  Widget _buildInvestmentCard(BuildContext context, ChildInvestmentModel inv, ChildProvider provider, bool isDark) {
    Color color;
    IconData icon;
    String badgeText = '${inv.expectedReturnRate}% p.a.';

    switch (inv.investmentType) {
      case 'SSY':
        color = const Color(0xFFEC4899);
        icon = Icons.local_florist_rounded;
        badgeText = '8.2% Tax Free';
        break;
      case 'MUTUAL_FUND_SIP':
        color = const Color(0xFF3B82F6);
        icon = Icons.trending_up_rounded;
        break;
      case 'PPF':
        color = const Color(0xFF10B981);
        icon = Icons.account_balance_rounded;
        break;
      case 'INSURANCE':
        color = const Color(0xFF8B5CF6);
        icon = Icons.health_and_safety_rounded;
        break;
      case 'GOLD':
        color = const Color(0xFFEAB308);
        icon = Icons.monetization_on_rounded;
        break;
      default:
        color = const Color(0xFFF59E0B);
        icon = Icons.lock_clock_rounded;
    }

    ChildProfileModel? child;
    try {
      child = provider.profiles.firstWhere((p) => p.id == inv.childId);
    } catch (_) {}

    return Dismissible(
      key: Key(inv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text('Delete Investment?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text('Delete "${inv.investmentName}"?', style: GoogleFonts.outfit()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(dCtx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteChildInvestment(inv.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditChildInvestmentScreen(investment: inv)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withAlpha(isDark ? 50 : 30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.investmentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                if (child != null)
                                  Text(
                                    'For: ${child.name}',
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invested', style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,##0').format(inv.investedAmount)}',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Value', style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,##0').format(inv.currentValuation)}',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                    if (inv.monthlyContribution > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Monthly SIP', style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${NumberFormat('#,##,##0').format(inv.monthlyContribution)}',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Future Goals Tab ---
  Widget _buildGoalsTab(BuildContext context, ChildProvider provider, bool isDark) {
    final goals = provider.filteredGoals;

    return goals.isEmpty
        ? _buildEmptyState(
            icon: Icons.flag_rounded,
            title: 'No Education Goals Planned',
            subtitle: 'Set a target for College (e.g. B.Tech / Medicine / Foreign Masters) with inflation calculation.',
            buttonLabel: '+ Plan Goal',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditChildGoalScreen(preselectedChildId: provider.selectedChildId),
              ),
            ),
            isDark: isDark,
          )
        : ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final g = goals[index];
              return _buildGoalCard(context, g, provider, isDark);
            },
          );
  }

  Widget _buildGoalCard(BuildContext context, ChildFutureGoalModel goal, ChildProvider provider, bool isDark) {
    final futureCost = goal.estimatedFutureCost;
    final accumulated = provider.totalCurrentValuation;
    final progress = (futureCost > 0) ? (accumulated / futureCost).clamp(0.0, 1.0) : 0.0;
    final suggestedSip = goal.calculateSuggestedMonthlySip(currentAccumulated: accumulated);

    ChildProfileModel? child;
    try {
      child = provider.profiles.firstWhere((p) => p.id == goal.childId);
    } catch (_) {}

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text('Delete Goal?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text('Delete "${goal.goalTitle}"?', style: GoogleFonts.outfit()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(dCtx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteChildFutureGoal(goal.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditChildGoalScreen(goal: goal)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.goalTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          if (child != null)
                            Text(
                              'For ${child.name} • Target Year ${goal.targetYear}',
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${goal.yearsRemaining} Yrs Left',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
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
                          Text("Today's Cost", style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,##0').format(goal.targetAmountToday)}',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Future Inflated Cost', style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,##0').format(futureCost)}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.grey.withAlpha(50),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Funded',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                    ),
                    Text(
                      'Target SIP: ₹${NumberFormat('#,##,##0').format(suggestedSip)}/mo',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(isDark ? 30 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(buttonLabel, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
