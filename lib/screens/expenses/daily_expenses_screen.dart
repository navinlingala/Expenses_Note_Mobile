import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

enum ExpensePeriod {
  today,
  thisWeek,
  thisMonth,
  customDay,
}

class DailyExpensesScreen extends StatefulWidget {
  const DailyExpensesScreen({super.key});

  @override
  State<DailyExpensesScreen> createState() => _DailyExpensesScreenState();
}

class _DailyExpensesScreenState extends State<DailyExpensesScreen> {
  ExpensePeriod _period = ExpensePeriod.today;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final Map<String, (IconData, Color)> _categoryMeta = {
    'Food & Dining': (Icons.restaurant_rounded, const Color(0xFFF97316)),
    'Groceries': (Icons.local_grocery_store_rounded, const Color(0xFF10B981)),
    'Fuel & Travel': (Icons.directions_car_rounded, const Color(0xFF0EA5E9)),
    'Shopping': (Icons.shopping_bag_rounded, const Color(0xFFEC4899)),
    'Bills & Utilities': (Icons.receipt_rounded, const Color(0xFF8B5CF6)),
    'Entertainment': (Icons.movie_rounded, const Color(0xFFF59E0B)),
    'Health & Medical': (Icons.medical_services_rounded, const Color(0xFFEF4444)),
    'Salary & Income': (Icons.payments_rounded, const Color(0xFF059669)),
    'Investments': (Icons.savings_rounded, const Color(0xFF4F46E5)),
    'General': (Icons.category_rounded, const Color(0xFF64748B)),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _prevDay() {
    setState(() {
      _period = ExpensePeriod.customDay;
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _period = ExpensePeriod.customDay;
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select Expense Date',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _period = ExpensePeriod.customDay;
      });
    }
  }

  // --- QUICK ADD EXPENSE MODAL ---
  void _showAddExpenseModal(BuildContext context, {String initialType = 'DEBIT'}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String type = initialType; // DEBIT (Expense) or CREDIT (Income)
    String category = type == 'DEBIT' ? 'Food & Dining' : 'Salary & Income';
    String paymentMode = 'UPI / GPay';
    DateTime expenseDate = _selectedDate;
    final amountController = TextEditingController();
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isExpense = type == 'DEBIT';

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isExpense ? '💸 Add Daily Expense (Cash Out)' : '💰 Add Income (Cash In)',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Toggle: Expense vs Income
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  type = 'DEBIT';
                                  category = 'Food & Dining';
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isExpense ? const Color(0xFFF43F5E) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '💸 Expense (Out)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isExpense ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  type = 'CREDIT';
                                  category = 'Salary & Income';
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isExpense ? const Color(0xFF10B981) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '💰 Income (In)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !isExpense ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Big Amount Input
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                        ),
                        hintText: '0',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isExpense ? const Color(0xFFF43F5E).withAlpha(80) : const Color(0xFF10B981).withAlpha(80),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Amount Chips
                    Wrap(
                      spacing: 8,
                      children: [50, 100, 200, 500, 1000].map((quickAmt) {
                        return ActionChip(
                          label: Text('+₹$quickAmt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final current = double.tryParse(amountController.text.trim()) ?? 0.0;
                            amountController.text = (current + quickAmt).toInt().toString();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Title / What did you spend on?
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: isExpense ? 'Title / What did you spend on?' : 'Income Title (e.g. Salary, Freelance)',
                        hintText: isExpense ? 'e.g., Lunch, Coffee, Petrol, Grocery' : 'e.g., Client Payment, Salary',
                        prefixIcon: Icon(isExpense ? Icons.shopping_bag_outlined : Icons.monetization_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Selection
                    const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoryMeta.keys.map((catKey) {
                        final isSel = category == catKey;
                        final meta = _categoryMeta[catKey]!;
                        return ChoiceChip(
                          avatar: Icon(meta.$1, size: 14, color: isSel ? Colors.white : meta.$2),
                          label: Text(catKey, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: meta.$2,
                          onSelected: (_) => setModalState(() => category = catKey),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Payment Mode
                    const Text('Payment Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['UPI / GPay', 'Cash', 'Debit Card', 'Credit Card', 'Net Banking'].map((mode) {
                        final isSel = paymentMode == mode;
                        return ChoiceChip(
                          label: Text(mode, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: const Color(0xFF6366F1),
                          onSelected: (_) => setModalState(() => paymentMode = mode),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Date selector row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_rounded, size: 18, color: Color(0xFF6366F1)),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${DateFormat('dd MMM yyyy').format(expenseDate)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: expenseDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(() => expenseDate = picked);
                            }
                          },
                          child: const Text('Change Date', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Optional Note
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Note / Remarks (Optional)',
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(
                          isExpense ? 'Save Expense' : 'Save Income',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () async {
                          final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount greater than 0')),
                            );
                            return;
                          }
                          final title = titleController.text.trim().isEmpty ? category : titleController.text.trim();
                          final noteText = noteController.text.trim();
                          final fullNotes = noteText.isEmpty ? paymentMode : '$paymentMode • $noteText';

                          final uid = context.read<AuthProvider>().currentUser?.id ?? 'default_user';
                          await context.read<TransactionProvider>().addTransaction(
                            userId: uid,
                            title: title,
                            amount: amt,
                            type: type,
                            dueDate: expenseDate,
                            category: category,
                            notes: fullNotes,
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$type of ₹${amt.toInt()} added for "$title"'),
                                backgroundColor: isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProv = context.watch<TransactionProvider>();
    final allTxs = txProv.transactions;

    final now = DateTime.now();

    // Filter transactions based on selected period
    List<TransactionModel> periodTxs = [];
    switch (_period) {
      case ExpensePeriod.today:
        periodTxs = allTxs.where((t) {
          return t.dueDate.year == now.year &&
              t.dueDate.month == now.month &&
              t.dueDate.day == now.day;
        }).toList();
        break;
      case ExpensePeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
        periodTxs = allTxs.where((t) {
          return t.dueDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              t.dueDate.isBefore(endOfWeek.add(const Duration(seconds: 1)));
        }).toList();
        break;
      case ExpensePeriod.thisMonth:
        periodTxs = allTxs.where((t) {
          return t.dueDate.year == now.year && t.dueDate.month == now.month;
        }).toList();
        break;
      case ExpensePeriod.customDay:
        periodTxs = allTxs.where((t) {
          return t.dueDate.year == _selectedDate.year &&
              t.dueDate.month == _selectedDate.month &&
              t.dueDate.day == _selectedDate.day;
        }).toList();
        break;
    }

    // Calculations
    final totalIn = periodTxs
        .where((t) => t.type == 'CREDIT')
        .fold(0.0, (s, t) => s + t.amount);

    final totalOut = periodTxs
        .where((t) => t.type == 'DEBIT')
        .fold(0.0, (s, t) => s + t.amount);

    final netCashflow = totalIn - totalOut;
    final isSurplus = netCashflow >= 0;

    final totalVolume = totalIn + totalOut;
    final inRatio = totalVolume > 0 ? (totalIn / totalVolume).clamp(0.0, 1.0) : 0.5;

    // Apply category & search filter
    var filteredDisplayList = periodTxs;
    if (_selectedCategoryFilter != 'All') {
      filteredDisplayList = filteredDisplayList.where((t) => t.category == _selectedCategoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filteredDisplayList = filteredDisplayList.where((t) {
        final titleMatch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final notesMatch = t.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return titleMatch || notesMatch;
      }).toList();
    }
    filteredDisplayList.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    // Category breakdown map for expenses
    final Map<String, double> categorySpend = {};
    for (var tx in periodTxs.where((t) => t.type == 'DEBIT')) {
      final cat = tx.category ?? 'General';
      categorySpend[cat] = (categorySpend[cat] ?? 0.0) + tx.amount;
    }

    String periodTitle;
    switch (_period) {
      case ExpensePeriod.today:
        periodTitle = 'Today • ${DateFormat('dd MMM').format(now)}';
        break;
      case ExpensePeriod.thisWeek:
        periodTitle = 'This Week';
        break;
      case ExpensePeriod.thisMonth:
        periodTitle = DateFormat('MMMM yyyy').format(now);
        break;
      case ExpensePeriod.customDay:
        periodTitle = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Expenses & Cashflow', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(
              periodTitle,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pick Date',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDate,
          ),
          IconButton(
            tooltip: 'Quick Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final uid = context.read<AuthProvider>().currentUser?.id;
              if (uid != null) {
                context.read<TransactionProvider>().loadTransactions(uid);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = context.read<AuthProvider>().currentUser?.id;
          if (uid != null) {
            await context.read<TransactionProvider>().loadTransactions(uid);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Period Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('Today', ExpensePeriod.today),
                  const SizedBox(width: 8),
                  _buildPeriodChip('This Week', ExpensePeriod.thisWeek),
                  const SizedBox(width: 8),
                  _buildPeriodChip('This Month', ExpensePeriod.thisMonth),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    _period == ExpensePeriod.customDay ? DateFormat('dd MMM').format(_selectedDate) : 'Pick Day',
                    ExpensePeriod.customDay,
                    icon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),

            if (_period == ExpensePeriod.customDay) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevDay,
                    tooltip: 'Previous Day',
                  ),
                  Text(
                    DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextDay,
                    tooltip: 'Next Day',
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Hero IN vs OUT Cashflow Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSurplus
                      ? [const Color(0xFF1E1B4B), const Color(0xFF4338CA), const Color(0xFF0284C7)]
                      : [const Color(0xFF4C0519), const Color(0xFF9F1239), const Color(0xFFE11D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isSurplus ? const Color(0xFF4338CA) : const Color(0xFF9F1239)).withAlpha(80),
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
                      Text(
                        'Net Balance • $periodTitle',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSurplus ? '✓ Surplus' : '⚠ Deficit',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isSurplus ? "+" : "-"}${CurrencyFormatter.format(netCashflow.abs())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // In & Out Two Boxes
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 16),
                                  SizedBox(width: 4),
                                  Text('CASH IN', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(totalIn),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 16),
                                  SizedBox(width: 4),
                                  Text('CASH OUT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(totalOut),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Visual Ratio Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: inRatio,
                          backgroundColor: const Color(0xFFF87171).withAlpha(180),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Add Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                    label: const Text('+ Expense (Out)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showAddExpenseModal(context, initialType: 'DEBIT'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('+ Income (In)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showAddExpenseModal(context, initialType: 'CREDIT'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Category Spend Carousel (if any expenses)
            if (categorySpend.isNotEmpty) ...[
              const Text('Spending by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categorySpend.entries.map((entry) {
                    final meta = _categoryMeta[entry.key] ?? (Icons.category_rounded, const Color(0xFF64748B));
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: meta.$2.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: meta.$2.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(meta.$1, size: 16, color: meta.$2),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              Text(
                                CurrencyFormatter.format(entry.value),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: meta.$2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Search Bar & Filter Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions (${filteredDisplayList.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (_selectedCategoryFilter != 'All')
                  TextButton(
                    onPressed: () => setState(() => _selectedCategoryFilter = 'All'),
                    child: const Text('Clear Filter', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by title, category, or note...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 14),

            // Itemized List
            if (filteredDisplayList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 54, color: isDark ? Colors.white30 : Colors.black26),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions recorded for $periodTitle',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "+ Expense" to record daily food, travel, shopping or bills.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ...filteredDisplayList.map((tx) => _buildExpenseCard(context, tx, isDark, txProv)),

            const SizedBox(height: 50),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_daily_expense',
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddExpenseModal(context),
      ),
    );
  }

  Widget _buildPeriodChip(String label, ExpensePeriod period, {IconData? icon}) {
    final isSel = _period == period;
    return ChoiceChip(
      avatar: icon != null ? Icon(icon, size: 14, color: isSel ? Colors.white : null) : null,
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      selected: isSel,
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(color: isSel ? Colors.white : null),
      onSelected: (_) {
        setState(() {
          _period = period;
          if (period == ExpensePeriod.today) {
            _selectedDate = DateTime.now();
          }
        });
      },
    );
  }

  Widget _buildExpenseCard(BuildContext context, TransactionModel tx, bool isDark, TransactionProvider txProv) {
    final isOut = tx.type == 'DEBIT';
    final meta = _categoryMeta[tx.category] ?? (isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, isOut ? const Color(0xFFF43F5E) : const Color(0xFF10B981));
    final color = isOut ? const Color(0xFFF43F5E) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: meta.$2.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(meta.$1, color: meta.$2, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tx.category ?? 'General',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (tx.notes?.isNotEmpty == true) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '• ${tx.notes}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isOut ? "-" : "+"}${CurrencyFormatter.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('hh:mm a').format(tx.dueDate),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'delete') {
                    txProv.softDeleteTransaction(tx.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF43F5E)),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
