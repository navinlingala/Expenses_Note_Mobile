import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loan_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/investment_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'loans/loan_list_screen.dart';
import 'investments/investment_list_screen.dart';
import 'expenses/daily_expenses_screen.dart';
import 'transactions/transaction_list_screen.dart';
import 'settings/settings_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LoanListScreen(),
    InvestmentListScreen(),
    DailyExpensesScreen(),
    TransactionListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.id;
      if (uid != null) {
        context.read<LoanProvider>().loadLoans(uid);
        context.read<TransactionProvider>().loadTransactions(uid);
        context.read<InvestmentProvider>().loadInvestments(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProv = context.watch<TransactionProvider>();
    final loanProv = context.watch<LoanProvider>();
    final invProv = context.watch<InvestmentProvider>();

    final pendingDuesCount = txProv.pendingReceivables.length + txProv.pendingPayables.length;
    final activeLoansCount = loanProv.activeLoans.length;
    final totalLoansDuesCount = activeLoansCount + pendingDuesCount;
    final activeInvestmentsCount = invProv.investments.length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            indicatorColor: const Color(0xFF6366F1).withAlpha(35),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF4F46E5))
                    : (isDark ? Colors.white60 : Colors.black54),
                letterSpacing: -0.1,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 20,
                color: isSelected
                    ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
                    : (isDark ? Colors.white54 : Colors.black45),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: totalLoansDuesCount > 0,
                  label: Text('$totalLoansDuesCount'),
                  child: const Icon(Icons.account_balance_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: totalLoansDuesCount > 0,
                  label: Text('$totalLoansDuesCount'),
                  child: const Icon(Icons.account_balance_rounded),
                ),
                label: 'Loans & Dues',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: activeInvestmentsCount > 0,
                  label: Text('$activeInvestmentsCount'),
                  child: const Icon(Icons.savings_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: activeInvestmentsCount > 0,
                  label: Text('$activeInvestmentsCount'),
                  child: const Icon(Icons.savings_rounded),
                ),
                label: 'Invest',
              ),
              const NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Expenses',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Cashflow',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
