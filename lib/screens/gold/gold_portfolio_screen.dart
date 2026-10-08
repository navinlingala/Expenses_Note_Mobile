import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gold_asset_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gold_provider.dart';
import 'add_edit_gold_asset_screen.dart';
import 'gold_asset_detail_screen.dart';

class GoldPortfolioScreen extends StatefulWidget {
  const GoldPortfolioScreen({super.key});

  @override
  State<GoldPortfolioScreen> createState() => _GoldPortfolioScreenState();
}

class _GoldPortfolioScreenState extends State<GoldPortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest_user';
      context.read<GoldProvider>().loadGoldAssets(userId);
    });
  }

  void _showRateAdjustmentSheet(BuildContext context, GoldProvider provider, bool isDark) {
    final rate24Ctrl = TextEditingController(text: provider.goldRate24K.toStringAsFixed(0));
    final rate22Ctrl = TextEditingController(text: provider.goldRate22K.toStringAsFixed(0));
    final rate18Ctrl = TextEditingController(text: provider.goldRate18K.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Live Gold Market Rates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Adjust gold price per gram in INR to automatically re-calculate your total portfolio valuation.',
                style: GoogleFonts.outfit(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 16),
              _buildRateInput('24K Gold Rate / gram (₹)', rate24Ctrl, isDark),
              const SizedBox(height: 12),
              _buildRateInput('22K (916) Gold Rate / gram (₹)', rate22Ctrl, isDark),
              const SizedBox(height: 12),
              _buildRateInput('18K Gold Rate / gram (₹)', rate18Ctrl, isDark),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final r24 = double.tryParse(rate24Ctrl.text.trim()) ?? provider.goldRate24K;
                    final r22 = double.tryParse(rate22Ctrl.text.trim());
                    final r18 = double.tryParse(rate18Ctrl.text.trim());
                    provider.updateGoldRates(rate24K: r24, rate22K: r22, rate18K: r18);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Market rates updated & portfolio re-valued.', style: GoogleFonts.outfit()),
                        backgroundColor: const Color(0xFFEAB308),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAB308),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Apply Rates', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateInput(String label, TextEditingController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFFEAB308)),
          ),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldProvider = context.watch<GoldProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308).withAlpha(isDark ? 50 : 30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFFEAB308), size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Gold Assets & Wealth',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAB308).withAlpha(80)),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFFEAB308), size: 20),
              tooltip: 'Live Gold Rates',
              onPressed: () => _showRateAdjustmentSheet(context, goldProvider, isDark),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditGoldAssetScreen()),
          );
        },
        backgroundColor: const Color(0xFFEAB308),
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Add Gold Asset', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest_user';
          await context.read<GoldProvider>().loadGoldAssets(userId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Luxury Gold Portfolio Grand Card
              _buildGrandPortfolioCard(goldProvider, isDark),

              const SizedBox(height: 14),

              // 2. Market Rates Pill Bar
              _buildMarketRatesBar(goldProvider, isDark),

              if (goldProvider.totalSgbAnnualInterest > 0) ...[
                const SizedBox(height: 14),
                // 3. SGB Passive Income Alert
                _buildSgbIncomeBanner(goldProvider, isDark),
              ],

              const SizedBox(height: 16),

              // 4. Category Filter Tabs
              _buildCategoryTabs(goldProvider, isDark),

              const SizedBox(height: 14),

              // 5. Assets List
              if (goldProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Color(0xFFEAB308)),
                  ),
                )
              else if (goldProvider.filteredAssets.isEmpty)
                _buildEmptyState(isDark)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goldProvider.filteredAssets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final asset = goldProvider.filteredAssets[idx];
                    return _buildAssetCard(asset, goldProvider, isDark);
                  },
                ),

              const SizedBox(height: 80), // Fab spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrandPortfolioCard(GoldProvider provider, bool isDark) {
    final totalGrams = provider.totalGoldWeightGrams;
    final totalTolas = provider.totalGoldWeightTolas;
    final currentVal = provider.totalCurrentMarketValue;
    final totalInvested = provider.totalInvestedAmount;
    final gain = provider.totalAbsoluteGain;
    final gainPercent = provider.totalGainPercentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFF92400E), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    const Icon(Icons.monetization_on_rounded, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'TOTAL GOLD ASSETS',
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
                  border: Border.all(color: Colors.amberAccent.withAlpha(100)),
                ),
                child: Text(
                  '${provider.assets.length} Assets',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.amberAccent,
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
                '${totalGrams.toStringAsFixed(1)} ',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Grams',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${totalTolas.toStringAsFixed(1)} Tola',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.amberAccent,
                  ),
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
                      'Valuation',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,##0').format(currentVal)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,##0').format(totalInvested)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Gain',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${gain >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(1)}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: gain >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
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

  Widget _buildMarketRatesBar(GoldProvider provider, bool isDark) {
    return GestureDetector(
      onTap: () => _showRateAdjustmentSheet(context, provider, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAB308).withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: Color(0xFFEAB308), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '24K: ₹${NumberFormat('#,##,##0').format(provider.goldRate24K)}/g  •  22K: ₹${NumberFormat('#,##,##0').format(provider.goldRate22K)}/g',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 13, color: Color(0xFFEAB308)),
          ],
        ),
      ),
    );
  }

  Widget _buildSgbIncomeBanner(GoldProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.creditGreen.withAlpha(isDark ? 28 : 18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.creditGreen.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppTheme.creditGreen, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'SGB 2.5% Annual Interest:',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '₹${NumberFormat('#,##,##0').format(provider.totalSgbAnnualInterest)}/yr',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.creditGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(GoldProvider provider, bool isDark) {
    final categories = [
      {'key': 'ALL', 'label': 'All Holdings'},
      {'key': 'JEWELRY', 'label': 'Jewelry (${provider.jewelryCount})'},
      {'key': 'COINS_BARS', 'label': 'Coins & Bars (${provider.coinAndBarCount})'},
      {'key': 'SGB', 'label': 'SGB Bonds (${provider.sgbHoldingCount})'},
      {'key': 'DIGITAL_ETF', 'label': 'Digital / ETF'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, idx) {
          final cat = categories[idx];
          final isSel = provider.selectedFilter == cat['key'];

          return GestureDetector(
            onTap: () => provider.setFilter(cat['key']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSel
                    ? const Color(0xFFEAB308)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  cat['label']!,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetCard(GoldAssetModel asset, GoldProvider provider, bool isDark) {
    final currentVal = asset.calculateCurrentValue(
      current24KRatePerGram: provider.goldRate24K,
      custom22KRatePerGram: provider.goldRate22K,
      custom18KRatePerGram: provider.goldRate18K,
    );
    final gain = asset.absoluteGain(
      current24KRatePerGram: provider.goldRate24K,
      custom22KRate: provider.goldRate22K,
      custom18KRate: provider.goldRate18K,
    );
    final gainPercent = asset.gainPercentage(
      current24KRatePerGram: provider.goldRate24K,
      custom22KRate: provider.goldRate22K,
      custom18KRate: provider.goldRate18K,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GoldAssetDetailScreen(asset: asset)),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(asset.typeEnum.icon, color: const Color(0xFFEAB308), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              asset.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAB308).withAlpha(isDark ? 40 : 20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              asset.purityEnum.shortName,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFEAB308),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${asset.weightInGrams.toStringAsFixed(1)}g (${asset.weightInTolas.toStringAsFixed(1)} Tola)${asset.lockerLocation != null ? ' • ${asset.lockerLocation}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##,##0').format(currentVal)}',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEAB308),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${gain >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: gain >= 0 ? AppTheme.creditGreen : AppTheme.debitRed,
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

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAB308).withAlpha(isDark ? 30 : 20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 36, color: Color(0xFFEAB308)),
          ),
          const SizedBox(height: 12),
          Text(
            'No Gold Assets Recorded',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your gold jewelry, coins, Sovereign Gold Bonds (SGB), and digital gold with live market valuations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditGoldAssetScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('Add First Gold Asset', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAB308),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
