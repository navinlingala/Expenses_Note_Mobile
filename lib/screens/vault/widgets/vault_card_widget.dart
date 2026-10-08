import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/vault_item_model.dart';

class VaultCardWidget extends StatefulWidget {
  final VaultItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const VaultCardWidget({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  State<VaultCardWidget> createState() => _VaultCardWidgetState();
}

class _VaultCardWidgetState extends State<VaultCardWidget> {
  bool _showSecrets = false;
  bool _isExpanded = false;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;

    switch (item.typeEnum) {
      case VaultItemType.card:
        return _buildCardItem(context, isDark);
      case VaultItemType.bankAccount:
        return _buildBankAccountItem(context, isDark);
      case VaultItemType.passwordPin:
        return _buildPasswordPinItem(context, isDark);
      case VaultItemType.secretNote:
        return _buildSecretNoteItem(context, isDark);
    }
  }

  // ===================== 1. CREDIT/DEBIT CARD VAULT ITEM =====================
  Widget _buildCardItem(BuildContext context, bool isDark) {
    final item = widget.item;
    final gradients = item.gradientColors;

    final displayCardNumber = _showSecrets
        ? (item.formattedCardNumber.isNotEmpty ? item.formattedCardNumber : item.accountOrCardNumber ?? '')
        : (item.maskedNumber.isNotEmpty ? item.maskedNumber : '•••• •••• •••• ••••');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradients.first.withAlpha(isDark ? 80 : 100),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Bank / Subtitle + Title + Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.subtitle != null && item.subtitle!.isNotEmpty)
                            Text(
                              item.subtitle!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: item.isFavorite ? const Color(0xFFFBBF24) : Colors.white70,
                            size: 22,
                          ),
                          onPressed: widget.onToggleFavorite,
                          tooltip: 'Favorite',
                        ),
                        IconButton(
                          icon: Icon(
                            _showSecrets ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => setState(() => _showSecrets = !_showSecrets),
                          tooltip: _showSecrets ? 'Mask Details' : 'Reveal Details',
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
                          onSelected: (val) {
                            if (val == 'edit') widget.onEdit();
                            if (val == 'delete') widget.onDelete();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete Item', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // EMV Chip + NFC
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.credit_card, size: 16, color: Colors.black54),
                    ),
                    const Icon(Icons.contactless_rounded, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 12),

                // Card Number with Quick Copy
                InkWell(
                  onTap: () {
                    if (item.accountOrCardNumber != null && item.accountOrCardNumber!.isNotEmpty) {
                      _copyToClipboard(context, item.accountOrCardNumber!.replaceAll(RegExp(r'\s+'), ''), 'Card Number');
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayCardNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom Meta: Card Holder, Expiry, CVV & PIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.holderName != null && item.holderName!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CARD HOLDER', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                          Text(
                            item.holderName!.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (item.expiryDate != null && item.expiryDate!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPIRES', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                          Text(
                            item.expiryDate!,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (item.cvv != null && item.cvv!.isNotEmpty)
                      InkWell(
                        onTap: () => _copyToClipboard(context, item.cvv!, 'CVV'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CVV', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showSecrets ? item.cvv! : '•••',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, color: Colors.white70, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (item.pin != null && item.pin!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ATM PIN', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                          Text(
                            _showSecrets ? item.pin! : '••••',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (item.notes != null && item.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Text(
                'Note: ${item.notes}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ===================== 2. BANK ACCOUNT VAULT ITEM =====================
  Widget _buildBankAccountItem(BuildContext context, bool isDark) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withAlpha(60)),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (item.subtitle != null && item.subtitle!.isNotEmpty)
                              Text(
                                item.subtitle!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: item.isFavorite ? const Color(0xFFFBBF24) : Colors.grey,
                            size: 20,
                          ),
                          onPressed: widget.onToggleFavorite,
                        ),
                        IconButton(
                          icon: Icon(_showSecrets ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                          onPressed: () => setState(() => _showSecrets = !_showSecrets),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          onSelected: (val) {
                            if (val == 'edit') widget.onEdit();
                            if (val == 'delete') widget.onDelete();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Account Number Row
                if (item.accountOrCardNumber != null && item.accountOrCardNumber!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'Account Number',
                    value: _showSecrets ? item.accountOrCardNumber! : item.maskedNumber,
                    copyValue: item.accountOrCardNumber!,
                    isDark: isDark,
                  ),

                // Holder Name
                if (item.holderName != null && item.holderName!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'Account Holder',
                    value: item.holderName!,
                    copyValue: item.holderName!,
                    isDark: isDark,
                  ),

                // IFSC Code
                if (item.ifscCode != null && item.ifscCode!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'IFSC Code',
                    value: item.ifscCode!,
                    copyValue: item.ifscCode!,
                    isDark: isDark,
                  ),

                // UPI ID
                if (item.upiId != null && item.upiId!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'UPI ID',
                    value: item.upiId!,
                    copyValue: item.upiId!,
                    isDark: isDark,
                  ),

                // PIN / Netbanking Password
                if (item.pin != null && item.pin!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'UPI / ATM PIN',
                    value: _showSecrets ? item.pin! : '••••',
                    copyValue: item.pin!,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
          if (item.notes != null && item.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Text(
                'Notes: ${item.notes}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // ===================== 3. PASSWORD / PIN VAULT ITEM =====================
  Widget _buildPasswordPinItem(BuildContext context, bool isDark) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(60)),
                          ),
                          child: const Icon(Icons.vpn_key_rounded, color: Color(0xFF8B5CF6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (item.category.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: item.isFavorite ? const Color(0xFFFBBF24) : Colors.grey,
                            size: 20,
                          ),
                          onPressed: widget.onToggleFavorite,
                        ),
                        IconButton(
                          icon: Icon(_showSecrets ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                          onPressed: () => setState(() => _showSecrets = !_showSecrets),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          onSelected: (val) {
                            if (val == 'edit') widget.onEdit();
                            if (val == 'delete') widget.onDelete();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Username / Email
                if (item.holderName != null && item.holderName!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'Username / Email',
                    value: item.holderName!,
                    copyValue: item.holderName!,
                    isDark: isDark,
                  ),

                // Password
                if (item.password != null && item.password!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'Password',
                    value: _showSecrets ? item.password! : '••••••••••••',
                    copyValue: item.password!,
                    isDark: isDark,
                  ),

                // PIN / Passcode
                if (item.pin != null && item.pin!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'Security PIN',
                    value: _showSecrets ? item.pin! : '••••',
                    copyValue: item.pin!,
                    isDark: isDark,
                  ),

                // Website / App
                if (item.urlOrApp != null && item.urlOrApp!.isNotEmpty)
                  _buildDataRow(
                    context,
                    label: 'Website / App URL',
                    value: item.urlOrApp!,
                    copyValue: item.urlOrApp!,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
          if (item.notes != null && item.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Text(
                'Note: ${item.notes}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // ===================== 4. SECRET NOTE VAULT ITEM =====================
  Widget _buildSecretNoteItem(BuildContext context, bool isDark) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                          ),
                          child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Category: ${item.category}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: item.isFavorite ? const Color(0xFFFBBF24) : Colors.grey,
                            size: 20,
                          ),
                          onPressed: widget.onToggleFavorite,
                        ),
                        IconButton(
                          icon: Icon(_showSecrets ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                          onPressed: () => setState(() => _showSecrets = !_showSecrets),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          onSelected: (val) {
                            if (val == 'edit') widget.onEdit();
                            if (val == 'delete') widget.onDelete();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Secret Note Content Box
                if (item.secretContent != null && item.secretContent!.isNotEmpty)
                  InkWell(
                    onTap: () => _copyToClipboard(context, item.secretContent!, 'Secret Note'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CONFIDENTIAL CONTENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _showSecrets ? item.secretContent! : '••••••••••••••••••••••••••••••••••••••••••••••••',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontFamily: _showSecrets ? null : 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (item.notes != null && item.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Text(
                'Note: ${item.notes}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context, {
    required String label,
    required String value,
    required String copyValue,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
            tooltip: 'Copy $label',
            onPressed: () => _copyToClipboard(context, copyValue, label),
          ),
        ],
      ),
    );
  }
}
