import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gold_asset_model.dart';
import '../../providers/gold_provider.dart';
import 'add_edit_gold_asset_screen.dart';

class GoldAssetDetailScreen extends StatefulWidget {
  final GoldAssetModel asset;

  const GoldAssetDetailScreen({super.key, required this.asset});

  @override
  State<GoldAssetDetailScreen> createState() => _GoldAssetDetailScreenState();
}

class _GoldAssetDetailScreenState extends State<GoldAssetDetailScreen> {
  late GoldAssetModel _currentAsset;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Gold Asset?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to permanently delete "${_currentAsset.title}" from your gold portfolio?',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.debitRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<GoldProvider>().deleteGoldAsset(_currentAsset.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gold asset removed from portfolio.', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.debitRed,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _openEditScreen() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditGoldAssetScreen(assetToEdit: _currentAsset)),
    );
    if (updated == true && mounted) {
      final fresh = context.read<GoldProvider>().assets.firstWhere(
            (a) => a.id == _currentAsset.id,
            orElse: () => _currentAsset,
          );
      setState(() => _currentAsset = fresh);
    }
  }

  Future<void> _showStatusUpdateSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = ['ACTIVE', 'SOLD', 'GIFTED', 'MATURED'];

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Holding Status',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...statuses.map((status) {
                final isCurrent = _currentAsset.status == status;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    status == 'ACTIVE'
                        ? Icons.check_circle_rounded
                        : status == 'SOLD'
                            ? Icons.sell_rounded
                            : status == 'GIFTED'
                                ? Icons.card_giftcard_rounded
                                : Icons.flag_rounded,
                    color: isCurrent ? const Color(0xFFEAB308) : Colors.grey,
                  ),
                  title: Text(
                    status,
                    style: GoogleFonts.outfit(
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      color: isCurrent ? const Color(0xFFEAB308) : null,
                    ),
                  ),
                  trailing: isCurrent ? const Icon(Icons.check, color: Color(0xFFEAB308)) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final updatedAsset = _currentAsset.copyWith(status: status);
                    final success = await context.read<GoldProvider>().updateGoldAsset(updatedAsset);
                    if (success && mounted) {
                      setState(() => _currentAsset = updatedAsset);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status updated to $status', style: GoogleFonts.outfit()),
                          backgroundColor: AppTheme.creditGreen,
                        ),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldProvider = context.watch<GoldProvider>();

    final currentVal = _currentAsset.calculateCurrentValue(
      current24KRatePerGram: goldProvider.goldRate24K,
      custom22KRatePerGram: goldProvider.goldRate22K,
      custom18KRatePerGram: goldProvider.goldRate18K,
    );
    final gain = _currentAsset.absoluteGain(
      current24KRatePerGram: goldProvider.goldRate24K,
      custom22KRate: goldProvider.goldRate22K,
      custom18KRate: goldProvider.goldRate18K,
    );
    final gainPercent = _currentAsset.gainPercentage(
      current24KRatePerGram: goldProvider.goldRate24K,
      custom22KRate: goldProvider.goldRate22K,
      custom18KRate: goldProvider.goldRate18K,
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text('Asset Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Asset',
            onPressed: _openEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.debitRed),
            tooltip: 'Delete Asset',
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withAlpha(80),
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
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_currentAsset.typeEnum.icon, color: Colors.amberAccent, size: 22),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amberAccent.withAlpha(120)),
                          ),
                          child: Text(
                            _currentAsset.purityEnum.shortName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentAsset.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currentAsset.typeEnum.displayName} • ${_currentAsset.status}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weight in Grams',
                              style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.white70),
                            ),
                            Text(
                              '${_currentAsset.weightInGrams.toStringAsFixed(2)} g',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 28, color: Colors.white24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weight in Tolas',
                              style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.white70),
                            ),
                            Text(
                              '${_currentAsset.weightInTolas.toStringAsFixed(2)} Tola',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.amberAccent,
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

            const SizedBox(height: 14),

            // 2. Financial Returns Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valuation & Returns Overview',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Purchase Cost',
                          value: '₹ ${NumberFormat('#,##,##0').format(_currentAsset.totalInvestedAmount)}',
                          caption: '@ ₹${NumberFormat('#,##,##0').format(_currentAsset.purchasePricePerGram)}/g',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Current Valuation',
                          value: '₹ ${NumberFormat('#,##,##0').format(currentVal)}',
                          caption: 'Live Market Rate',
                          valueColor: const Color(0xFFEAB308),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gain >= 0
                          ? AppTheme.creditGreen.withAlpha(isDark ? 30 : 18)
                          : AppTheme.debitRed.withAlpha(isDark ? 30 : 18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            gain >= 0 ? 'Profit:' : 'Loss:',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: gain >= 0 ? AppTheme.creditGreen : AppTheme.debitRed,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${gain >= 0 ? '+' : ''}₹${NumberFormat('#,##,##0').format(gain)} (${gainPercent.toStringAsFixed(1)}%)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: gain >= 0 ? AppTheme.creditGreen : AppTheme.debitRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_currentAsset.isSgb) ...[
              const SizedBox(height: 14),
              // SGB Special Interest Insights Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                        : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.creditGreen.withAlpha(100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.creditGreen, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'RBI Sovereign Gold Bond',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Annual 2.5%:',
                            style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##,##0').format(_currentAsset.sgbAnnualInterest)}/yr',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.creditGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '6-Month Payout:',
                            style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##,##0').format(_currentAsset.sgbSemiAnnualInterest)}',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.creditGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 3. Locker & Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Locker & Security Details',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Purchase Date',
                    value: DateFormat('dd MMM yyyy').format(_currentAsset.purchaseDate),
                    isDark: isDark,
                  ),
                  if (_currentAsset.lockerLocation != null)
                    _buildDetailRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Locker / Safe',
                      value: _currentAsset.lockerLocation!,
                      isDark: isDark,
                    ),
                  if (_currentAsset.huidNumber != null)
                    _buildDetailRow(
                      icon: Icons.qr_code_2_rounded,
                      label: 'HUID Hallmark No.',
                      value: _currentAsset.huidNumber!,
                      isDark: isDark,
                      onTap: () => _copyToClipboard(_currentAsset.huidNumber!, 'HUID Number'),
                    ),
                  if (_currentAsset.jewelerName != null)
                    _buildDetailRow(
                      icon: Icons.storefront_outlined,
                      label: 'Jeweler / Merchant',
                      value: _currentAsset.jewelerName!,
                      isDark: isDark,
                    ),
                  if (_currentAsset.makingCharges > 0)
                    _buildDetailRow(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Making / Wastage',
                      value: '₹ ${NumberFormat('#,##,##0').format(_currentAsset.makingCharges)}',
                      isDark: isDark,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showStatusUpdateSheet,
                    icon: const Icon(Icons.sync_alt_rounded, size: 16),
                    label: Text(
                      _currentAsset.status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openEditScreen,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text('Edit', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAB308),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String caption,
    Color? valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 9.5, color: isDark ? Colors.white38 : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
