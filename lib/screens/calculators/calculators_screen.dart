
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../loans/add_loan_screen.dart';
import '../investments/add_investment_screen.dart';

class CalculatorsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const CalculatorsScreen({super.key, this.onOpenDrawer});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Loan EMI State
  double _loanPrincipal = 500000;
  double _loanRate = 10.5;
  int _loanTenureYears = 5;
  bool _showAmortization = false;

  // 2. SIP Wealth Planner State
  double _sipMonthly = 5000;
  double _sipExpectedRate = 12.0;
  int _sipTenureYears = 10;
  bool _showSipBreakdown = false;

  // 3. Lump Sum Investment State
  double _lumpAmount = 100000;
  double _lumpExpectedRate = 12.0;
  int _lumpTenureYears = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOAN EMI CALCULATION ---
  // Formula: EMI = [P x r x (1+r)^n] / [(1+r)^n - 1]
  Map<String, dynamic> _calculateEmi() {
    final p = _loanPrincipal;
    final r = (_loanRate / 12) / 100;
    final n = _loanTenureYears * 12;

    if (p <= 0 || r <= 0 || n <= 0) {
      return {'emi': 0.0, 'totalInterest': 0.0, 'totalPayment': 0.0, 'schedule': []};
    }

    final powFactor = pow(1 + r, n).toDouble();
    final emi = (p * r * powFactor) / (powFactor - 1);
    final totalPayment = emi * n;
    final totalInterest = totalPayment - p;

    // Generate year-wise schedule
    List<Map<String, dynamic>> schedule = [];
    double remainingBalance = p;

    for (int y = 1; y <= _loanTenureYears; y++) {
      double yearInterest = 0;
      double yearPrincipal = 0;

      for (int m = 1; m <= 12; m++) {
        final monthlyInterest = remainingBalance * r;
        final monthlyPrincipal = emi - monthlyInterest;
        yearInterest += monthlyInterest;
        yearPrincipal += monthlyPrincipal;
        remainingBalance = max(0, remainingBalance - monthlyPrincipal);
      }

      schedule.add({
        'year': y,
        'principalPaid': yearPrincipal,
        'interestPaid': yearInterest,
        'balance': remainingBalance,
      });
    }

    return {
      'emi': emi,
      'totalInterest': totalInterest,
      'totalPayment': totalPayment,
      'principalRatio': (p / totalPayment).clamp(0.0, 1.0),
      'interestRatio': (totalInterest / totalPayment).clamp(0.0, 1.0),
      'schedule': schedule,
    };
  }

  // --- SIP CALCULATION ---
  // Formula: M = P * [ (1 + i)^n - 1 ] / i * (1 + i)
  Map<String, dynamic> _calculateSip() {
    final p = _sipMonthly;
    final i = (_sipExpectedRate / 12) / 100;
    final n = _sipTenureYears * 12;

    if (p <= 0 || i <= 0 || n <= 0) {
      return {'invested': 0.0, 'returns': 0.0, 'total': 0.0, 'yearly': []};
    }

    final totalInvested = p * n;
    final powFactor = pow(1 + i, n).toDouble();
    final totalMaturity = p * ((powFactor - 1) / i) * (1 + i);
    final wealthGain = max(0.0, totalMaturity - totalInvested);

    List<Map<String, dynamic>> yearly = [];
    for (int y = 1; y <= _sipTenureYears; y++) {
      final months = y * 12;
      final inv = p * months;
      final curFactor = pow(1 + i, months).toDouble();
      final curVal = p * ((curFactor - 1) / i) * (1 + i);
      yearly.add({
        'year': y,
        'invested': inv,
        'value': curVal,
        'returns': max(0.0, curVal - inv),
      });
    }

    return {
      'invested': totalInvested,
      'returns': wealthGain,
      'total': totalMaturity,
      'investedRatio': (totalInvested / totalMaturity).clamp(0.0, 1.0),
      'returnsRatio': (wealthGain / totalMaturity).clamp(0.0, 1.0),
      'yearly': yearly,
    };
  }

  // --- LUMP SUM CALCULATION ---
  // Formula: A = P * (1 + r)^t
  Map<String, dynamic> _calculateLumpSum() {
    final p = _lumpAmount;
    final r = _lumpExpectedRate / 100;
    final t = _lumpTenureYears;

    if (p <= 0 || r <= 0 || t <= 0) {
      return {'invested': 0.0, 'returns': 0.0, 'total': 0.0};
    }

    final totalVal = p * pow(1 + r, t).toDouble();
    final gain = max(0.0, totalVal - p);

    return {
      'invested': p,
      'returns': gain,
      'total': totalVal,
      'investedRatio': (p / totalVal).clamp(0.0, 1.0),
      'returnsRatio': (gain / totalVal).clamp(0.0, 1.0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            tooltip: Navigator.canPop(context) && widget.onOpenDrawer == null ? 'Back' : 'Open Side Menu',
            icon: Icon(
              Navigator.canPop(context) && widget.onOpenDrawer == null
                  ? Icons.arrow_back_rounded
                  : Icons.menu_rounded,
            ),
            onPressed: () {
              if (Navigator.canPop(context) && widget.onOpenDrawer == null) {
                Navigator.pop(context);
              } else if (widget.onOpenDrawer != null) {
                widget.onOpenDrawer!();
              } else {
                Scaffold.of(scaffoldContext).openDrawer();
              }
            },
          ),
        ),
        title: const Text('Financial Calculators', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_rounded, size: 20), text: 'Loan EMI'),
            Tab(icon: Icon(Icons.trending_up_rounded, size: 20), text: 'SIP Wealth'),
            Tab(icon: Icon(Icons.savings_rounded, size: 20), text: 'Lump Sum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoanEmiTab(isDark),
          _buildSipPlannerTab(isDark),
          _buildLumpSumTab(isDark),
        ],
      ),
    );
  }

  // ================= 1. LOAN EMI TAB =================
  Widget _buildLoanEmiTab(bool isDark) {
    final res = _calculateEmi();
    final emi = res['emi'] as double;
    final totalInterest = res['totalInterest'] as double;
    final totalPayment = res['totalPayment'] as double;
    final principalRatio = res['principalRatio'] as double;
    final interestRatio = res['interestRatio'] as double;
    final schedule = res['schedule'] as List<Map<String, dynamic>>;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Result Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3730A3), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withAlpha(50),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Loan EMI', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(emi),
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Interest', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.format(totalInterest), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Payment', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.format(totalPayment), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Visual Proportion Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (principalRatio * 100).toInt(),
                        child: Container(color: const Color(0xFF6366F1)),
                      ),
                      Expanded(
                        flex: (interestRatio * 100).toInt(),
                        child: Container(color: const Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Principal: ${(principalRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Interest: ${(interestRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Interactive Sliders & Inputs
        _sliderCard(
          isDark: isDark,
          title: 'Loan Principal Amount',
          valueDisplay: CurrencyFormatter.format(_loanPrincipal),
          min: 10000,
          max: 5000000,
          current: _loanPrincipal,
          stepCount: 499,
          onChanged: (val) => setState(() => _loanPrincipal = val),
        ),

        const SizedBox(height: 12),

        _sliderCard(
          isDark: isDark,
          title: 'Annual Interest Rate (%)',
          valueDisplay: '${_loanRate.toStringAsFixed(1)}% p.a.',
          min: 5.0,
          max: 24.0,
          current: _loanRate,
          stepCount: 190,
          onChanged: (val) => setState(() => _loanRate = val),
        ),

        const SizedBox(height: 12),

        _sliderCard(
          isDark: isDark,
          title: 'Loan Tenure (Years)',
          valueDisplay: '$_loanTenureYears Years (${_loanTenureYears * 12} Months)',
          min: 1,
          max: 30,
          current: _loanTenureYears.toDouble(),
          stepCount: 29,
          onChanged: (val) => setState(() => _loanTenureYears = val.toInt()),
        ),

        const SizedBox(height: 16),

        // Add to My Loans Quick Action Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Add this as Active Loan in App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddLoanScreen()),
            );
          },
        ),

        const SizedBox(height: 16),

        // Amortization Schedule Accordion
        InkWell(
          onTap: () => setState(() => _showAmortization = !_showAmortization),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1), size: 20),
                    SizedBox(width: 8),
                    Text('Yearly Amortization Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Icon(_showAmortization ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              ],
            ),
          ),
        ),

        if (_showAmortization) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(const Color(0xFF6366F1).withAlpha(20)),
              columns: const [
                DataColumn(label: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Principal Paid', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Interest Paid', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Remaining Balance', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: schedule.map((item) {
                return DataRow(cells: [
                  DataCell(Text('Yr ${item['year']}')),
                  DataCell(Text(CurrencyFormatter.format(item['principalPaid']))),
                  DataCell(Text(CurrencyFormatter.format(item['interestPaid']))),
                  DataCell(Text(CurrencyFormatter.format(item['balance']), style: const TextStyle(fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ================= 2. SIP PLANNER TAB =================
  Widget _buildSipPlannerTab(bool isDark) {
    final res = _calculateSip();
    final invested = res['invested'] as double;
    final returns = res['returns'] as double;
    final total = res['total'] as double;
    final investedRatio = res['investedRatio'] as double;
    final returnsRatio = res['returnsRatio'] as double;
    final yearly = res['yearly'] as List<Map<String, dynamic>>;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Wealth Projection Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withAlpha(50),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expected Future Wealth Valuation', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(total),
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Invested', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.format(invested), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Est. Wealth Gain', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.format(returns), style: const TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Visual Proportion Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Investment vs Returns Growth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (investedRatio * 100).toInt(),
                        child: Container(color: const Color(0xFF0EA5E9)),
                      ),
                      Expanded(
                        flex: (returnsRatio * 100).toInt(),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Invested: ${(investedRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Gain: ${(returnsRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Inputs & Sliders
        _sliderCard(
          isDark: isDark,
          title: 'Monthly SIP Investment (₹)',
          valueDisplay: CurrencyFormatter.format(_sipMonthly),
          min: 500,
          max: 100000,
          current: _sipMonthly,
          stepCount: 199,
          onChanged: (val) => setState(() => _sipMonthly = val),
        ),

        const SizedBox(height: 12),

        _sliderCard(
          isDark: isDark,
          title: 'Expected Annual Return (%)',
          valueDisplay: '${_sipExpectedRate.toStringAsFixed(1)}% p.a.',
          min: 6.0,
          max: 30.0,
          current: _sipExpectedRate,
          stepCount: 240,
          onChanged: (val) => setState(() => _sipExpectedRate = val),
        ),

        const SizedBox(height: 12),

        _sliderCard(
          isDark: isDark,
          title: 'Time Horizon (Years)',
          valueDisplay: '$_sipTenureYears Years',
          min: 1,
          max: 35,
          current: _sipTenureYears.toDouble(),
          stepCount: 34,
          onChanged: (val) => setState(() => _sipTenureYears = val.toInt()),
        ),

        const SizedBox(height: 16),

        // Add to Investments Action Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.savings_rounded),
          label: const Text('Add as SIP Portfolio in App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
            );
          },
        ),

        const SizedBox(height: 16),

        // Growth Milestones
        InkWell(
          onTap: () => setState(() => _showSipBreakdown = !_showSipBreakdown),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text('Compounding Milestones by Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Icon(_showSipBreakdown ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              ],
            ),
          ),
        ),

        if (_showSipBreakdown) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(const Color(0xFF10B981).withAlpha(20)),
              columns: const [
                DataColumn(label: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Total Invested', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Wealth Returns', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Total Valuation', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: yearly.map((item) {
                return DataRow(cells: [
                  DataCell(Text('Yr ${item['year']}')),
                  DataCell(Text(CurrencyFormatter.format(item['invested']))),
                  DataCell(Text(CurrencyFormatter.format(item['returns']), style: const TextStyle(color: Color(0xFF10B981)))),
                  DataCell(Text(CurrencyFormatter.format(item['value']), style: const TextStyle(fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ================= 3. LUMP SUM TAB =================
  Widget _buildLumpSumTab(bool isDark) {
    final res = _calculateLumpSum();
    final invested = res['invested'] as double;
    final returns = res['returns'] as double;
    final total = res['total'] as double;
    final investedRatio = res['investedRatio'] as double;
    final returnsRatio = res['returnsRatio'] as double;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withAlpha(50),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Maturity Value (One-time Investment)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(total),
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Initial Deposit', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.format(invested), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Compound Gain', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.format(returns), style: const TextStyle(color: Color(0xFF93C5FD), fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Visual Proportion Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Deposit vs Growth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (investedRatio * 100).toInt(),
                        child: Container(color: const Color(0xFF64748B)),
                      ),
                      Expanded(
                        flex: (returnsRatio * 100).toInt(),
                        child: Container(color: const Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF64748B), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Deposit: ${(investedRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Profit: ${(returnsRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        _sliderCard(
          isDark: isDark,
          title: 'Total Investment Amount (₹)',
          valueDisplay: CurrencyFormatter.format(_lumpAmount),
          min: 5000,
          max: 2000000,
          current: _lumpAmount,
          stepCount: 399,
          onChanged: (val) => setState(() => _lumpAmount = val),
        ),

        const SizedBox(height: 12),

        _sliderCard(
          isDark: isDark,
          title: 'Annual Return Rate (%)',
          valueDisplay: '${_lumpExpectedRate.toStringAsFixed(1)}% p.a.',
          min: 4.0,
          max: 25.0,
          current: _lumpExpectedRate,
          stepCount: 210,
          onChanged: (val) => setState(() => _lumpExpectedRate = val),
        ),

        const SizedBox(height: 12),

        _sliderCard(
          isDark: isDark,
          title: 'Period (Years)',
          valueDisplay: '$_lumpTenureYears Years',
          min: 1,
          max: 30,
          current: _lumpTenureYears.toDouble(),
          stepCount: 29,
          onChanged: (val) => setState(() => _lumpTenureYears = val.toInt()),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.savings_rounded),
          label: const Text('Add to Lump Sum Assets in App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // --- REUSABLE SLIDER CARD WITH DIRECT TEXT PREVIEW ---
  Widget _sliderCard({
    required bool isDark,
    required String title,
    required String valueDisplay,
    required double min,
    required double max,
    required double current,
    required int stepCount,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueDisplay,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: const Color(0xFF6366F1),
              overlayColor: const Color(0xFF6366F1).withAlpha(40),
              trackHeight: 4,
            ),
            child: Slider(
              min: min,
              max: max,
              divisions: stepCount,
              value: current.clamp(min, max),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
