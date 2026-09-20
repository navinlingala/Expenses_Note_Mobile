import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../trash/trash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification Preferences
  bool _inAppNotifications = true;
  bool _soundAndVibrate = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  // WhatsApp Alert Preferences
  bool _whatsAppAlerts = true;
  bool _selfAlerts = true;
  bool _borrowerAlerts = true;
  final String _myWhatsAppNumber = '9010067464';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final loanProv = context.watch<LoanProvider>();
    final txProv = context.watch<TransactionProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. User Profile Account Card
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.chat_rounded, size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '+91 $_myWhatsAppNumber',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 2. In-App Device Notifications Card
          const Text('In-App Device Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                  title: const Text('Device Alarms & Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Timely heads-up banner notifications for due dates', style: TextStyle(fontSize: 12)),
                  value: _inAppNotifications,
                  activeThumbColor: const Color(0xFF6366F1),
                  onChanged: (val) {
                    setState(() => _inAppNotifications = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'In-app notifications enabled' : 'In-app notifications muted'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded, size: 20, color: Colors.grey),
                  title: const Text('Sound & Vibration Alert', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Play chime & vibrate when reminder triggers', style: TextStyle(fontSize: 11)),
                  value: _soundAndVibrate && _inAppNotifications,
                  onChanged: _inAppNotifications
                      ? (val) => setState(() => _soundAndVibrate = val)
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded, size: 20, color: Colors.grey),
                  title: const Text('Daily Morning Reminder Time', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '${_reminderTime.format(context)} (Scheduled exact alarm)',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 18),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() => _reminderTime = picked);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline_rounded, size: 20, color: Color(0xFF6366F1)),
                  title: const Text('Test In-App Notification Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                  subtitle: const Text('Fires a sample heads-up alarm in 3 seconds', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await NotificationService.instance.scheduleNotification(
                      id: 99999,
                      title: '🔔 EMI Reminder: Personal Loan',
                      body: 'Your upcoming EMI of ₹27,886 is due tomorrow morning!',
                      scheduledDate: DateTime.now().add(const Duration(seconds: 3)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification scheduled for 3 seconds from now! Check your device banner.'),
                          backgroundColor: Color(0xFF6366F1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. WhatsApp Automated Alerts Hub
          const Text('WhatsApp Notification Center', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF25D366).withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Official WhatsApp Channel', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                '+91 $_myWhatsAppNumber',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF25D366)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _whatsAppAlerts ? const Color(0xFF25D366).withAlpha(30) : Colors.grey.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _whatsAppAlerts ? 'ACTIVE' : 'DISABLED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _whatsAppAlerts ? const Color(0xFF25D366) : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Master Toggle
                SwitchListTile(
                  title: const Text('Master WhatsApp Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Enable bank-grade WhatsApp message alerts and dispatching', style: TextStyle(fontSize: 11)),
                  value: _whatsAppAlerts,
                  activeThumbColor: const Color(0xFF25D366),
                  onChanged: (val) => setState(() => _whatsAppAlerts = val),
                ),
                const Divider(height: 1),

                // Self Reminders Toggle
                SwitchListTile(
                  title: const Text('Send EMI & Debt Reminders to My WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Receive loan EMI & bill reminders on +91 $_myWhatsAppNumber', style: const TextStyle(fontSize: 11)),
                  value: _selfAlerts && _whatsAppAlerts,
                  activeThumbColor: const Color(0xFF25D366),
                  onChanged: _whatsAppAlerts
                      ? (val) => setState(() => _selfAlerts = val)
                      : null,
                ),
                const Divider(height: 1),

                // Borrower Notices Toggle
                SwitchListTile(
                  title: const Text('Borrower Payment Notices (Who Owes Me)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Allow 1-click professional reminder messages to people who owe you', style: TextStyle(fontSize: 11)),
                  value: _borrowerAlerts && _whatsAppAlerts,
                  activeThumbColor: const Color(0xFF25D366),
                  onChanged: _whatsAppAlerts
                      ? (val) => setState(() => _borrowerAlerts = val)
                      : null,
                ),
                const Divider(height: 1),

                // Testing & Template Hub Button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Test Bank-Grade WhatsApp Alerts (3 Templates)'),
                      onPressed: () => _showWhatsAppTestingCenter(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Trash & Maintenance Section
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFF43F5E)),
                  title: const Text('Trash & Deleted Items'),
                  subtitle: Text(
                    '${loanProv.deletedLoans.length + txProv.deletedTransactions.length} items in recycle bin',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrashScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  subtitle: const Text('End current session and lock offline database', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    await NotificationService.instance.cancelAll();
                    loanProv.clearData();
                    txProv.clearData();
                    if (context.mounted) {
                      auth.logout();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showWhatsAppTestingCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WhatsAppTestingSheet(userPhone: _myWhatsAppNumber),
    );
  }
}

class _WhatsAppTestingSheet extends StatefulWidget {
  final String userPhone;
  const _WhatsAppTestingSheet({required this.userPhone});

  @override
  State<_WhatsAppTestingSheet> createState() => _WhatsAppTestingSheetState();
}

class _WhatsAppTestingSheetState extends State<_WhatsAppTestingSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _phoneController.text = widget.userPhone;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                  SizedBox(width: 8),
                  Text('WhatsApp Alert Testing Hub', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Test professional, bank-grade WhatsApp alerts with zero emoji errors:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Target Phone input
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Send Test Alert To Phone Number',
              hintText: 'e.g. 9010067464',
              prefixText: '+91 ',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 14),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF25D366),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF25D366),
            tabs: const [
              Tab(text: '1. Borrower Due Notice'),
              Tab(text: '2. Loan EMI Alert'),
              Tab(text: '3. Self Payable Reminder'),
            ],
          ),
          const SizedBox(height: 14),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Borrower Due Notice Preview
                _buildPreviewTab(
                  context,
                  title: 'Borrower Payment Notice (Who Owes Me)',
                  description: 'Sent to borrowers/friends who owe you money.',
                  message: WhatsAppService.instance.generateBorrowerDueReminder(
                    personName: 'Keerthi',
                    amount: 1500,
                    dueDate: DateTime.now().add(const Duration(days: 2)),
                    title: 'Lent for travel / Freelance balance',
                    customNote: 'Personal loan clearance',
                  ),
                ),

                // 2. Loan EMI Alert Preview
                _buildPreviewTab(
                  context,
                  title: 'Monthly Loan EMI Alert',
                  description: 'Scheduled alert sent for your active bank/lender loan EMI.',
                  message: WhatsAppService.instance.generateLoanEmiReminder(
                    loanTitle: 'personal loan',
                    lenderName: 'piramal',
                    emiAmount: 27886,
                    dueDay: 5,
                    paidEmis: 24,
                    totalEmis: 60,
                    remainingBalance: 1003896,
                    nextDueDate: DateTime.now().add(const Duration(days: 5)),
                  ),
                ),

                // 3. Self Payable Reminder Preview
                _buildPreviewTab(
                  context,
                  title: 'Self Payment Reminder (Whom I Owe)',
                  description: 'Reminds you about upcoming rent, bills, or dues you have to pay.',
                  message: WhatsAppService.instance.generateSelfPayableReminder(
                    payeeName: 'House Owner / Suresh',
                    amount: 12000,
                    dueDate: DateTime.now().add(const Duration(days: 3)),
                    title: 'Monthly House Rent',
                    customNote: 'To be settled via UPI',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab(BuildContext context, {
    required String title,
    required String description,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                message,
                style: const TextStyle(fontSize: 13, height: 1.4, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send This Alert to WhatsApp Now'),
            onPressed: () async {
              final targetNumber = _phoneController.text.trim();
              if (targetNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a target mobile number')),
                );
                return;
              }

              final success = await WhatsAppService.instance.sendReminder(
                phoneNumber: targetNumber,
                message: message,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'WhatsApp alert opened cleanly!' : 'Could not launch WhatsApp.'),
                    backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
