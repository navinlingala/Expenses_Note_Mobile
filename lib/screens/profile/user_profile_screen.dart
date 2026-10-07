import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/investment_provider.dart';
import '../settings/settings_screen.dart';

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
        title: const Text('Edit Personal Profile'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp / Mobile Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g. 9010067464',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
                    content: Text('Profile details updated successfully!'),
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
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out from Expenses Note on this device?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Log Out'),
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
        appBar: AppBar(title: const Text('Account Profile')),
        body: const Center(child: Text('No active user found.')),
      );
    }

    final totalLoanBalance = loanProv.activeLoans.fold<double>(0.0, (sum, l) => sum + l.remainingBalance);
    final totalAssets = invProv.totalCurrentValue + txProv.totalToReceive;
    final totalLiabilities = totalLoanBalance + txProv.totalToPay;
    final netWorth = totalAssets - totalLiabilities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Profile', style: TextStyle(fontWeight: FontWeight.w800)),
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
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Modern Fintech Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withAlpha(60),
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
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4F46E5),
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  auth.isGuest ? 'GUEST' : 'ACTIVE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          if (user.phone?.isNotEmpty == true) ...[
                            const SizedBox(height: 3),
                            Text(
                              '📱 ${user.phone}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
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
                    Text(
                      'Member Since: ${AppDateUtils.formatShort(user.createdAt)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    InkWell(
                      onTap: () => _showEditProfileDialog(context, user.name, user.phone),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Edit Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Personal Financial Footprint (Real-time Health Summary)
          const Text(
            'Financial Footprint',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Net Standing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      CurrencyFormatter.format(netWorth),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: netWorth >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _footprintMiniCard(
                        title: 'Total Assets',
                        value: CurrencyFormatter.format(totalAssets),
                        subtitle: 'Investments + Receivables',
                        color: const Color(0xFF10B981),
                        icon: Icons.trending_up_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _footprintMiniCard(
                        title: 'Total Liabilities',
                        value: CurrencyFormatter.format(totalLiabilities),
                        subtitle: 'Loans + Payables',
                        color: const Color(0xFFF43F5E),
                        icon: Icons.trending_down_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. User Preferences & Settings
          const Text(
            'Preferences & Security',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _preferenceTile(
                  icon: Icons.notifications_active_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: 'WhatsApp & App Reminders',
                  subtitle: 'Configure automated alerts & timings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _preferenceTile(
                  icon: Icons.currency_rupee_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Default Currency',
                  subtitle: 'Indian Rupee (₹)',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Default currency is set to INR (₹)')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _preferenceTile(
                  icon: Icons.cloud_done_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Cloud Database Status',
                  subtitle: 'Neon PostgreSQL Synced',
                  trailingText: 'Active',
                  onTap: () async {
                    await loanProv.loadLoans(user.id);
                    await txProv.loadTransactions(user.id);
                    await invProv.loadInvestments(user.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cloud database data freshly synced!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Clean Logout Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF43F5E),
                side: const BorderSide(color: Color(0xFFF43F5E), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                auth.isGuest ? 'Exit Guest Session' : 'Log Out of Account',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () => _confirmLogout(context),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _footprintMiniCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferenceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: trailingText != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trailingText,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
    );
  }
}
