import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/credit_card_model.dart';
import '../../models/credit_card_transaction_model.dart';
import '../../providers/credit_card_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_edit_credit_card_screen.dart';
import 'add_edit_card_transaction_screen.dart';
import 'record_card_payment_dialog.dart';

class CreditCardsHubScreen extends StatefulWidget {
  const CreditCardsHubScreen({super.key});

  @override
  State<CreditCardsHubScreen> createState() => _CreditCardsHubScreenState();
}

class _CreditCardsHubScreenState extends State<CreditCardsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final PageController _cardPageController = PageController(viewportFraction: 0.90);
  int _currentCardIndex = 0;
  bool _showCardSecrets = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id ?? 'guest_user';
      Provider.of<CreditCardProvider>(context, listen: false).loadData(userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              child: const Icon(Icons.credit_card_rounded, color: Color(0xFF6366F1), size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Credit Cards Hub',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(
                    'Usages & Bill Reminders',
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
              icon: const Icon(Icons.add_card_rounded, color: Color(0xFF6366F1), size: 20),
              tooltip: 'Add Credit Card',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditCreditCardScreen()),
                );
              },
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
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
              onPressed: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final userId = auth.currentUser?.id ?? 'guest_user';
                Provider.of<CreditCardProvider>(context, listen: false).loadData(userId);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Consumer<CreditCardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.cards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cards.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final userId = auth.currentUser?.id ?? 'guest_user';
              await provider.loadData(userId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPortfolioOverviewCard(provider, isDark),
                  const SizedBox(height: 16),
                  _buildBestCardRecommendation(provider, isDark),
                  const SizedBox(height: 18),
                  _buildSectionHeader('YOUR CREDIT CARDS (${provider.cards.length})'),
                  const SizedBox(height: 10),
                  _buildCardCarousel(provider, isDark),
                  const SizedBox(height: 16),
                  _buildQuickActionButtons(provider, isDark),
                  const SizedBox(height: 18),
                  _buildUpcomingRemindersStrip(provider, isDark),
                  const SizedBox(height: 20),
                  _buildSegmentedTabsHeader(isDark),
                  const SizedBox(height: 12),
                  _buildActiveTabView(provider, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                size: 72,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Credit Cards Added Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your credit cards to track limit utilization, statement generation dates, due payment reminders, and record bill clearances.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditCreditCardScreen()),
                );
              },
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Add Your First Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioOverviewCard(CreditCardProvider provider, bool isDark) {
    final health = provider.overallUtilizationHealth;
    final healthColor = health == 'HEALTHY'
        ? const Color(0xFF10B981)
        : (health == 'MODERATE' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            color: const Color(0xFF4F46E5).withAlpha(isDark ? 60 : 80),
            blurRadius: 16,
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
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TOTAL CREDIT UTILIZATION',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: healthColor.withAlpha(150), width: 1),
                ),
                child: Text(
                  '${provider.overallUtilizationPercentage.toStringAsFixed(1)}% Used',
                  style: TextStyle(
                    color: healthColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencyFormat.format(provider.totalCurrentOutstanding),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'due of ${currencyFormat.format(provider.totalCreditLimit)} limit',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (provider.overallUtilizationPercentage / 100.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewMetric(
                'Available Credit',
                currencyFormat.format(provider.totalAvailableLimit),
                const Color(0xFF34D399),
              ),
              _buildOverviewMetric(
                'Active Cards',
                '${provider.cards.where((c) => c.status == 'ACTIVE').length}',
                Colors.white,
              ),
              _buildOverviewMetric(
                'CIBIL Impact',
                health == 'HEALTHY' ? 'Excellent' : (health == 'MODERATE' ? 'Moderate' : 'High Alert'),
                healthColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBestCardRecommendation(CreditCardProvider provider, bool isDark) {
    final bestCard = provider.bestCardToSpendToday;
    if (bestCard == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withAlpha(80) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withAlpha(isDark ? 80 : 120),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best Card to Spend Today',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use ${bestCard.cardName} (${bestCard.bankName}) to get ~${bestCard.daysUntilStatement + 20} interest-free days!',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : const Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCardCarousel(CreditCardProvider provider, bool isDark) {
    final cards = provider.cards;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _cardPageController,
            itemCount: cards.length,
            onPageChanged: (index) {
              setState(() {
                _currentCardIndex = index;
              });
              provider.selectCard(cards[index].id);
            },
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildRealisticCreditCard(card, isDark),
              );
            },
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              cards.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentCardIndex == index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentCardIndex == index
                      ? const Color(0xFF6366F1)
                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRealisticCreditCard(CreditCardModel card, bool isDark) {
    final gradients = card.gradientColors;

    final displayCardNumber = _showCardSecrets
        ? (card.cardNumber != null && card.cardNumber!.isNotEmpty
            ? card.formattedCardNumber
            : '•••• •••• •••• ${card.displayLast4}')
        : card.maskedCardNumber;

    return Container(
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
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.bankName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      card.cardName,
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
                      _showCardSecrets ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: _showCardSecrets ? 'Mask Card Number' : 'Reveal Card Number',
                    onPressed: () => setState(() => _showCardSecrets = !_showCardSecrets),
                  ),
                  _buildNetworkBadge(card.cardNetwork),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFD97706), width: 1),
                    ),
                    child: const Icon(Icons.nfc_rounded, size: 16, color: Color(0xFF78350F)),
                  ),
                  if (card.cvv != null && card.cvv!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        'CVV: ${_showCardSecrets ? card.cvv! : "•••"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  final textToCopy = (card.cardNumber != null && card.cardNumber!.isNotEmpty)
                      ? card.cardNumber!.replaceAll(RegExp(r'\s+'), '')
                      : card.displayLast4;
                  Clipboard.setData(ClipboardData(text: textToCopy));
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Card Number ($textToCopy) copied!'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayCardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OUTSTANDING', style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.5)),
                  Text(
                    currencyFormat.format(card.currentOutstanding),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (card.expiryDate != null && card.expiryDate!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('EXPIRES', style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.5)),
                    Text(
                      card.expiryDate!,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('AVAILABLE LIMIT', style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.5)),
                  Text(
                    currencyFormat.format(card.availableLimit),
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkBadge(String network) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        network.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(CreditCardProvider provider, bool isDark) {
    final selectedCard = provider.selectedCard;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: selectedCard == null
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => RecordCardPaymentDialog(card: selectedCard),
                    );
                  },
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Pay / Clear Bill', overflow: TextOverflow.ellipsis),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: selectedCard == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditCardTransactionScreen(preselectedCardId: selectedCard.id),
                      ),
                    );
                  },
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text('+ Log Spend', overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingRemindersStrip(CreditCardProvider provider, bool isDark) {
    final upcomingDue = provider.upcomingDueBills;
    final upcomingStatements = provider.upcomingStatements;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text(
                'BILLING CYCLES & REMINDERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcomingDue.isNotEmpty) ...[
            _buildReminderTile(
              title: 'Payment Due for ${upcomingDue.first.cardName}',
              subtitle: '${currencyFormat.format(upcomingDue.first.currentOutstanding)} due in ${upcomingDue.first.daysUntilDue} days (${DateFormat('dd MMM').format(upcomingDue.first.nextDueDate)})',
              icon: Icons.error_outline_rounded,
              iconColor: const Color(0xFFEF4444),
              badgeText: '${upcomingDue.first.daysUntilDue}d left',
              badgeColor: const Color(0xFFEF4444),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
          ],
          if (upcomingStatements.isNotEmpty) ...[
            _buildReminderTile(
              title: 'Statement Date: ${upcomingStatements.first.cardName}',
              subtitle: 'Bill generation on ${DateFormat('dd MMM').format(upcomingStatements.first.nextStatementDate)} (${upcomingStatements.first.daysUntilStatement} days to closing)',
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF3B82F6),
              badgeText: 'Cycle close',
              badgeColor: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabsHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Spends'),
          Tab(text: 'Card Settings'),
          Tab(text: 'EMIs'),
        ],
        onTap: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildActiveTabView(CreditCardProvider provider, bool isDark) {
    switch (_tabController.index) {
      case 0:
        return _buildTransactionsTab(provider, isDark);
      case 1:
        return _buildCardSettingsTab(provider, isDark);
      case 2:
        return _buildEmisTab(provider, isDark);
      default:
        return _buildTransactionsTab(provider, isDark);
    }
  }

  Widget _buildTransactionsTab(CreditCardProvider provider, bool isDark) {
    final txs = provider.selectedCardTransactions;
    final selectedCard = provider.selectedCard;

    if (txs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'No Spends Logged for ${selectedCard?.cardName ?? 'Card'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Log swipes, online shopping, or bill payments on this card to track your statement balance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: txs.map((tx) => _buildTransactionCard(tx, provider, isDark)).toList(),
    );
  }

  Widget _buildTransactionCard(CreditCardTransactionModel tx, CreditCardProvider provider, bool isDark) {
    final isPayment = tx.transactionType == 'PAYMENT';
    final isRefund = tx.transactionType == 'REFUND';
    final amountColor = (isPayment || isRefund) ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final prefix = (isPayment || isRefund) ? '- ' : '+ ';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amountColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPayment ? Icons.payments_rounded : (isRefund ? Icons.replay_rounded : _getCategoryIcon(tx.category)),
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchantName ?? tx.category,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(tx.transactionDate),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    if (tx.isEmi) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tx.emiMonths}M EMI',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${currencyFormat.format(tx.amount)}',
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey),
                onPressed: () => _confirmDeleteTransaction(tx, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'SHOPPING':
        return Icons.shopping_bag_rounded;
      case 'DINING':
        return Icons.restaurant_rounded;
      case 'GROCERIES':
        return Icons.local_grocery_store_rounded;
      case 'FUEL':
        return Icons.local_gas_station_rounded;
      case 'BILLS':
        return Icons.receipt_rounded;
      case 'TRAVEL':
        return Icons.flight_takeoff_rounded;
      case 'ENTERTAINMENT':
        return Icons.movie_rounded;
      case 'HEALTHCARE':
        return Icons.medical_services_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  Widget _buildCardSettingsTab(CreditCardProvider provider, bool isDark) {
    final selectedCard = provider.selectedCard;
    if (selectedCard == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedCard.cardName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditCreditCardScreen(existingCard: selectedCard),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                    onPressed: () => _confirmDeleteCard(selectedCard, provider),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          _buildDetailRow('Bank Name', selectedCard.bankName),
          _buildDetailRow('Card Network', selectedCard.cardNetwork),
          _buildDetailRow('Total Credit Limit', currencyFormat.format(selectedCard.totalLimit)),
          _buildDetailRow('Current Outstanding', currencyFormat.format(selectedCard.currentOutstanding)),
          _buildDetailRow('Available Limit', currencyFormat.format(selectedCard.availableLimit)),
          _buildDetailRow('Statement Generation Day', '${selectedCard.statementDay}th of every month'),
          _buildDetailRow('Payment Due Day', '${selectedCard.dueDay}th of every month'),
          _buildDetailRow('Interest Free Days', '${selectedCard.interestFreeDays} Days'),
          _buildDetailRow('Reminders', selectedCard.reminderEnabled ? 'Enabled 🔔' : 'Disabled 🔕'),
          if (selectedCard.notes != null && selectedCard.notes!.isNotEmpty)
            _buildDetailRow('Notes', selectedCard.notes!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmisTab(CreditCardProvider provider, bool isDark) {
    final emis = provider.selectedCardTransactions.where((t) => t.isEmi).toList();

    if (emis.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 10),
            const Text(
              'No Active EMIs on this Card',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'When logging a spend, turn on "Convert to EMI" to monitor installment schedules.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: emis.map((emi) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emi.merchantName ?? emi.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${currencyFormat.format(emi.amount)} (${emi.emiMonths ?? 0} Months)',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currencyFormat.format(emi.monthlyEmiAmount ?? (emi.amount / (emi.emiMonths ?? 1)))}/mo',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), fontSize: 13),
                  ),
                  const Text('Monthly EMI', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmDeleteTransaction(CreditCardTransactionModel tx, CreditCardProvider provider) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'guest_user';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This will remove the transaction record and adjust the card balance accordingly.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteTransaction(tx.id, userId, cardId: tx.cardId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCard(CreditCardModel card, CreditCardProvider provider) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'guest_user';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${card.cardName}?'),
        content: const Text('This will permanently delete this credit card and all associated transactions and billing records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteCreditCard(card.id, userId);
            },
            child: const Text('Delete Card'),
          ),
        ],
      ),
    );
  }
}
