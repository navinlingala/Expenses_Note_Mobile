import 'calculators/calculators_screen.dart';
import 'income/family_income_screen.dart';
import '../providers/income_provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loan_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/investment_provider.dart';
import '../widgets/app_drawer.dart';
import 'dashboard/dashboard_screen.dart';
import 'loans/loan_list_screen.dart';
import 'dues/dues_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Color(0xFFF43F5E)),
            SizedBox(width: 8),
            Text('Exit Expenses Note?'),
          ],
        ),
        content: const Text('Are you sure you want to close the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _navigateToIndex(int idx) {
    setState(() => _currentIndex = idx);
  }

  late final List<Widget> _screens = [
    DashboardScreen(onOpenDrawer: _openDrawer),
    LoanListScreen(onOpenDrawer: _openDrawer),
    DuesScreen(onOpenDrawer: _openDrawer),
    InvestmentListScreen(onOpenDrawer: _openDrawer),
    const DailyExpensesScreen(),
    const TransactionListScreen(),
    const SettingsScreen(),
    FamilyIncomeScreen(onOpenDrawer: _openDrawer),
    CalculatorsScreen(onOpenDrawer: _openDrawer),
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
        context.read<IncomeProvider>().loadIncomes(uid);
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
    final activeInvestmentsCount = invProv.investments.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If drawer is open, close drawer
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // If user is on a sub-screen (not Dashboard), back swipe goes to Dashboard first
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // If already on Dashboard, prompt confirmation before exiting
        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
      drawer: AppDrawer(
        selectedIndex: _currentIndex,
        onItemSelected: _navigateToIndex,
      ),
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
            selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
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
                  isLabelVisible: activeLoansCount > 0,
                  label: Text('$activeLoansCount'),
                  child: const Icon(Icons.account_balance_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: activeLoansCount > 0,
                  label: Text('$activeLoansCount'),
                  child: const Icon(Icons.account_balance_rounded),
                ),
                label: 'Loans',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingDuesCount > 0,
                  label: Text('$pendingDuesCount'),
                  child: const Icon(Icons.people_alt_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingDuesCount > 0,
                  label: Text('$pendingDuesCount'),
                  child: const Icon(Icons.people_alt_rounded),
                ),
                label: 'Dues',
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
            ],
          ),
        ),
      ),
      ),
    );
  }
}
