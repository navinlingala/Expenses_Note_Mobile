import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/vault_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import 'add_edit_vault_item_screen.dart';
import 'widgets/vault_card_widget.dart';

class VaultHubScreen extends StatefulWidget {
  const VaultHubScreen({super.key});

  @override
  State<VaultHubScreen> createState() => _VaultHubScreenState();
}

class _VaultHubScreenState extends State<VaultHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pinInputController = TextEditingController();
  String _pinErrorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id ?? 'guest_user';
      final vaultProvider = Provider.of<VaultProvider>(context, listen: false);
      vaultProvider.loadVaultItems(userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pinInputController.dispose();
    super.dispose();
  }

  void _showAddOptionModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                const Text(
                  'Add to Secure Vault',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select category of secret information to store',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _buildModalTile(
                  ctx,
                  icon: Icons.credit_card_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Credit / Debit Card',
                  subtitle: 'Card number, CVV, Expiry & ATM PIN',
                  type: 'CARD',
                ),
                _buildModalTile(
                  ctx,
                  icon: Icons.account_balance_rounded,
                  color: const Color(0xFF3B82F6),
                  title: 'Bank Account & NetBanking',
                  subtitle: 'Account number, IFSC, UPI ID & Passwords',
                  type: 'BANK_ACCOUNT',
                ),
                _buildModalTile(
                  ctx,
                  icon: Icons.vpn_key_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Password & Security PIN',
                  subtitle: 'App logins, WiFi passwords, credentials',
                  type: 'PASSWORD_PIN',
                ),
                _buildModalTile(
                  ctx,
                  icon: Icons.security_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Confidential Secret Note',
                  subtitle: 'Locker codes, Identity records, Recovery keys',
                  type: 'SECRET_NOTE',
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildModalTile(
    BuildContext ctx, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String type,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      onTap: () {
        Navigator.pop(ctx);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditVaultItemScreen(initialType: type),
          ),
        );
      },
    );
  }

  void _showMasterPinDialog(BuildContext context, VaultProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 10),
            Text(provider.isPinSet ? 'Vault Master PIN' : 'Set Master PIN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.isPinSet
                  ? 'Update or change your 4-digit Vault Master PIN'
                  : 'Protect your secrets with a 4-digit Master PIN',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter 4-Digit PIN',
                hintText: '••••',
                prefixIcon: Icon(Icons.lock_rounded),
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          if (provider.isPinSet)
            TextButton(
              onPressed: () async {
                await provider.removeMasterPin();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Master PIN removed.'), backgroundColor: Colors.orange),
                );
              },
              child: const Text('Disable PIN', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 4) {
                await provider.setMasterPin(pin);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Master PIN saved!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vaultProvider = Provider.of<VaultProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(50)),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Personal Secret Vault',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(
                    'Cards, PINs & Secret Notes',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
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
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: Icon(
                vaultProvider.isVaultUnlocked ? Icons.lock_outline_rounded : Icons.lock_rounded,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              tooltip: vaultProvider.isVaultUnlocked ? 'Lock Vault / PIN Settings' : 'Unlock',
              onPressed: () => _showMasterPinDialog(context, vaultProvider),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 22),
              tooltip: 'Add Secret',
              onPressed: () => _showAddOptionModal(context),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vaultProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !vaultProvider.isVaultUnlocked
              ? _buildLockScreen(vaultProvider, isDark)
              : _buildUnlockedDashboard(vaultProvider, isDark),
      floatingActionButton: vaultProvider.isVaultUnlocked
          ? FloatingActionButton.extended(
              onPressed: () => _showAddOptionModal(context),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Secret', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ===================== LOCK SCREEN =====================
  Widget _buildLockScreen(VaultProvider provider, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(80), width: 2),
              ),
              child: const Icon(Icons.lock_rounded, size: 40, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 20),
            Text(
              'Secure Vault Locked',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your 4-digit Master PIN to view your cards, passwords, and secret information.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _pinInputController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  errorText: _pinErrorMessage.isNotEmpty ? _pinErrorMessage : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onSubmitted: (val) => _verifyAndUnlock(provider),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _verifyAndUnlock(provider),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unlock Vault', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyAndUnlock(VaultProvider provider) {
    final entered = _pinInputController.text.trim();
    if (provider.verifyPin(entered)) {
      setState(() {
        _pinErrorMessage = '';
        _pinInputController.clear();
      });
    } else {
      setState(() {
        _pinErrorMessage = 'Incorrect PIN. Try again.';
      });
    }
  }

  // ===================== UNLOCKED DASHBOARD =====================
  Widget _buildUnlockedDashboard(VaultProvider provider, bool isDark) {
    final filteredItems = provider.filteredVaultItems;

    return RefreshIndicator(
      onRefresh: () async {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final userId = auth.currentUser?.id ?? 'guest_user';
        await provider.loadVaultItems(userId);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // METRIC CARDS OVERVIEW
            _buildVaultMetrics(provider, isDark),
            const SizedBox(height: 16),

            // SEARCH BAR
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cards, banks, passwords, secret notes...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                provider.setSearchQuery(val);
                setState(() {});
              },
            ),
            const SizedBox(height: 14),

            // CATEGORY FILTER CHIPS
            _buildCategoryChips(provider, isDark),
            const SizedBox(height: 16),

            // VAULT ITEMS LIST
            if (filteredItems.isEmpty)
              _buildEmptyState(isDark)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return VaultCardWidget(
                    item: item,
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditVaultItemScreen(existingItem: item),
                        ),
                      );
                    },
                    onDelete: () => _confirmDeleteItem(context, provider, item),
                    onToggleFavorite: () => provider.toggleFavorite(item.id),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultMetrics(VaultProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withAlpha(isDark ? 80 : 100),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secure Vault Status', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Offline & Protected', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.totalSecretsCount} Secrets',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Cards', '${provider.cardsCount}', Icons.credit_card_rounded),
              _buildMiniMetric('Bank Acc', '${provider.bankAccountsCount}', Icons.account_balance_rounded),
              _buildMiniMetric('PIN/Pass', '${provider.passwordsCount}', Icons.vpn_key_rounded),
              _buildMiniMetric('Notes', '${provider.secretNotesCount}', Icons.notes_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildCategoryChips(VaultProvider provider, bool isDark) {
    final categories = [
      {'key': 'ALL', 'label': 'All (${provider.totalSecretsCount})'},
      {'key': 'CARD', 'label': 'Cards (${provider.cardsCount})'},
      {'key': 'BANK_ACCOUNT', 'label': 'Bank Acc (${provider.bankAccountsCount})'},
      {'key': 'PASSWORD_PIN', 'label': 'PIN/Pass (${provider.passwordsCount})'},
      {'key': 'SECRET_NOTE', 'label': 'Notes (${provider.secretNotesCount})'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = provider.selectedTypeFilter == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                cat['label']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF6366F1),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
              onSelected: (val) {
                if (val) provider.setTypeFilter(cat['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Secret Items Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Store your credit/debit card numbers, CVVs, bank details, passwords, and private notes safely.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddOptionModal(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Secret'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteItem(BuildContext context, VaultProvider provider, VaultItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Secret Item?'),
        content: Text('Are you sure you want to remove "${item.title}" from your Secure Vault?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await provider.deleteVaultItem(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted from vault.'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
