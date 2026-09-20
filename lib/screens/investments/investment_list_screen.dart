import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/investment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/investment_provider.dart';
import '../trash/trash_screen.dart';
import 'add_investment_screen.dart';
import 'investment_detail_screen.dart';

class InvestmentListScreen extends StatefulWidget {
  const InvestmentListScreen({super.key});

  @override
  State<InvestmentListScreen> createState() => _InvestmentListScreenState();
}

class _InvestmentListScreenState extends State<InvestmentListScreen> {
  String _selectedCategory = 'ALL';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invProv = context.watch<InvestmentProvider>();
    final auth = context.watch<AuthProvider>();

    final allActive = invProv.investments;
    final query = _searchController.text.trim().toLowerCase();

    final filtered = allActive.where((inv) {
      final matchesCategory = _selectedCategory == 'ALL' ||
          inv.category.toUpperCase() == _selectedCategory.toUpperCase();
      final matchesQuery = query.isEmpty ||
          inv.title.toLowerCase().contains(query) ||
          inv.categoryDisplayName.toLowerCase().contains(query) ||
          (inv.notes ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    final totalInvested = invProv.totalInvested;
    final totalCurrentValue = invProv.totalCurrentValue;
    final totalGain = invProv.totalGainLoss;
    final gainPercent = invProv.overallGainPercentage;
    final isProfitable = invProv.isOverallProfitable;
    final estMonthly = invProv.totalExpectedMonthlyReturn;
    final estAnnual = invProv.totalExpectedAnnualReturn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments Portfolio'),
        actions: [
          IconButton(
            tooltip: 'View Trash',
            icon: Badge(
              isLabelVisible: invProv.deletedInvestments.isNotEmpty,
              label: Text('${invProv.deletedInvestments.length}'),
              child: const Icon(Icons.delete_outline_rounded),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Portfolio',
            onPressed: () {
              final uid = auth.currentUser?.id;
              if (uid != null) {
                invProv.loadInvestments(uid);
              }
            },
          ),
        ],
      ),
      floatingActionButton: allActive.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_add_inv',
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen()));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Investment'),
            ),
      body: Column(
        children: [
          // 1. Portfolio Value & Return Hero Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF3730A3), const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withAlpha(80),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Portfolio Valuation',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isProfitable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isProfitable ? "+" : ""}${gainPercent.toStringAsFixed(2)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(totalCurrentValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Invested: ${CurrencyFormatter.format(totalInvested)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white54)),
                    const SizedBox(width: 8),
                    Text(
                      'Gain: ${isProfitable ? "+" : ""}${CurrencyFormatter.format(totalGain)}',
                      style: TextStyle(
                        color: isProfitable ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),

                // Passive Return Estimates Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_graph_rounded, size: 14, color: Color(0xFF6EE7B7)),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Est. Monthly Return', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            Text(
                              '+${CurrencyFormatter.format(estMonthly)} / mo',
                              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(height: 20, width: 1, color: Colors.white24),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF93C5FD)),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Est. Yearly Return', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            Text(
                              '+${CurrencyFormatter.format(estAnnual)} / yr',
                              style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stocks, mutual funds, FDs...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // 3. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                _categoryChip('ALL', 'All (${allActive.length})'),
                _categoryChip('MUTUAL_FUNDS', 'Mutual Funds'),
                _categoryChip('STOCKS', 'Stocks & Equity'),
                _categoryChip('FIXED_DEPOSIT', 'FD / PPF'),
                _categoryChip('GOLD', 'Gold & SGB'),
                _categoryChip('REAL_ESTATE', 'Real Estate'),
                _categoryChip('CRYPTO', 'Crypto'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 4. Investment List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.savings_outlined,
                              size: 48,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allActive.isEmpty
                                ? 'Build Your Wealth Portfolio'
                                : 'No Matching Assets Found',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            allActive.isEmpty
                                ? 'Track stocks, mutual funds, FDs, gold, and real estate with real-time monthly and yearly return projections.'
                                : 'Try searching with a different keyword or category filter.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          if (allActive.isEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen()));
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Add Investment',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _selectedCategory = 'ALL');
                              },
                              icon: const Icon(Icons.clear_all_rounded, size: 16),
                              label: const Text('Reset All Filters'),
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final inv = filtered[index];
                      return _buildInvestmentCard(context, inv, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF6366F1).withAlpha(40),
        onSelected: (_) => setState(() => _selectedCategory = key),
      ),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, InvestmentModel inv, bool isDark) {
    final isProfitable = inv.isProfitable;
    final color = _getCategoryColor(inv.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvestmentDetailScreen(investmentId: inv.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Icon, Title, and Return Pill
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withAlpha(30),
                    child: Icon(_getCategoryIcon(inv.category), color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              inv.categoryDisplayName,
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                            if (inv.investmentType == 'SIP') ...[
                              const Text(' • ', style: TextStyle(color: Colors.grey)),
                              const Text(
                                'SIP',
                                style: TextStyle(fontSize: 10, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isProfitable ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isProfitable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '${isProfitable ? "+" : ""}${inv.gainPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isProfitable ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Values Row: Current Value, Invested, Estimated Returns
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Value', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(inv.currentValue),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Invested', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(inv.investedAmount),
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Est. Monthly Return', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        '+${CurrencyFormatter.format(inv.expectedMonthlyReturn)}/mo',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toUpperCase()) {
      case 'MUTUAL_FUNDS':
        return Icons.trending_up_rounded;
      case 'STOCKS':
        return Icons.show_chart_rounded;
      case 'FIXED_DEPOSIT':
        return Icons.lock_clock_rounded;
      case 'GOLD':
        return Icons.monetization_on_rounded;
      case 'REAL_ESTATE':
        return Icons.domain_rounded;
      case 'CRYPTO':
        return Icons.currency_bitcoin_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toUpperCase()) {
      case 'MUTUAL_FUNDS':
        return const Color(0xFF6366F1);
      case 'STOCKS':
        return const Color(0xFF0EA5E9);
      case 'FIXED_DEPOSIT':
        return const Color(0xFF10B981);
      case 'GOLD':
        return const Color(0xFFF59E0B);
      case 'REAL_ESTATE':
        return const Color(0xFF8B5CF6);
      case 'CRYPTO':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF64748B);
    }
  }
}
