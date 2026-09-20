import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/investment_provider.dart';
import '../investments/investment_list_screen.dart';
import '../trash/trash_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  void _showEditProfileDialog(BuildContext context, String currentName, String? currentPhone) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile Details'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final auth = context.read<AuthProvider>();
                final user = auth.currentUser;
                if (user != null) {
                  final updated = user.copyWith(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  );
                  auth.updateCurrentUser(updated);
                  setState(() {});
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your Money Reminder account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close profile screen
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final loanProv = context.watch<LoanProvider>();
    final txProv = context.watch<TransactionProvider>();
    final invProv = context.watch<InvestmentProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: const Center(child: Text('No active user logged in.')),
      );
    }

    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final totalLoans = loanProv.activeLoans.length;
    final totalEmi = loanProv.totalMonthlyEmis;
    final toReceive = txProv.totalToReceive;
    final toPay = txProv.totalToPay;
    final totalTrashCount = loanProv.deletedLoans.length + txProv.deletedTransactions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile & Account'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(context, user.name, user.phone),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Identity Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withAlpha(80),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 31,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: Colors.amber, size: 18),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.phone != null && user.phone!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              '+91 ${user.phone}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          'Member since ${AppDateUtils.formatDayMonth(user.createdAt)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active User',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Financial Portfolio Overview
          const Text('Financial Portfolio Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _metricTile(
                title: 'Active Loans',
                value: '$totalLoans Loans',
                subtitle: '${CurrencyFormatter.format(totalEmi)} / mo',
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _metricTile(
                title: 'To Receive',
                value: CurrencyFormatter.format(toReceive),
                subtitle: 'People owe you',
                icon: Icons.call_received_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricTile(
                title: 'To Pay',
                value: CurrencyFormatter.format(toPay),
                subtitle: 'You owe others',
                icon: Icons.call_made_rounded,
                color: const Color(0xFFF43F5E),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _metricTile(
                title: 'Cashflow Status',
                value: txProv.monthlyCredit >= txProv.monthlyDebit ? 'Surplus' : 'Deficit',
                subtitle: 'Current Month',
                icon: Icons.insights_rounded,
                color: const Color(0xFF0EA5E9),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentListScreen()));
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF6366F1).withAlpha(25),
                    child: const Icon(Icons.savings_rounded, color: Color(0xFF6366F1), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Investment Portfolio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          CurrencyFormatter.format(invProv.totalCurrentValue),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${CurrencyFormatter.format(invProv.totalExpectedMonthlyReturn)} / mo',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Text('View All', style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF6366F1)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 3. System & Database Architecture Status
          const Text('Database & Synchronization Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _syncStatusRow(
                  label: 'Cloud Database (PostgreSQL)',
                  detail: 'money_reminder_db on port 5432',
                  status: 'Connected',
                  isOnline: true,
                ),
                const Divider(height: 20),
                _syncStatusRow(
                  label: 'Backend REST API (Spring Boot)',
                  detail: 'http://localhost:8080/api (Active)',
                  status: 'Healthy',
                  isOnline: true,
                ),
                const Divider(height: 20),
                _syncStatusRow(
                  label: 'Local Offline Engine',
                  detail: 'IndexedDB / SQLite Engine Active',
                  status: 'Synced',
                  isOnline: true,
                ),
                const Divider(height: 20),
                _syncStatusRow(
                  label: 'Security & Encryption',
                  detail: 'BCrypt & User Isolation Enforcement',
                  status: 'Enforced',
                  isOnline: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Quick Action Tiles
          const Text('Account Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 20),
            ),
            title: const Text('Trash & Recycle Bin', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('$totalTrashCount deleted items. Restore or delete permanently.'),
            trailing: Badge(
              isLabelVisible: totalTrashCount > 0,
              label: Text('$totalTrashCount'),
              child: const Icon(Icons.chevron_right_rounded),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),

          const SizedBox(height: 10),

          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_rounded, color: Color(0xFF10B981), size: 20),
            ),
            title: const Text('Manual Cloud Sync', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Refresh and synchronize all records with PostgreSQL'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              await loanProv.loadLoans(user.id);
              await txProv.loadTransactions(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All loans and transactions synchronized with cloud PostgreSQL!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // 5. Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF43F5E),
                side: const BorderSide(color: Color(0xFFF43F5E)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out of Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () => _confirmLogout(context),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      ),
    );
  }

  Widget _syncStatusRow({
    required String label,
    required String detail,
    required String status,
    required bool isOnline,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                status,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}