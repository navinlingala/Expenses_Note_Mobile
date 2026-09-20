import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import '../trash/trash_screen.dart';
import '../profile/user_profile_screen.dart';

enum DateFilterMode {
  month,
  day,
  range,
  allTime,
}

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  DateFilterMode _filterMode = DateFilterMode.month;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime? _selectedDay;
  DateTimeRange? _selectedDateRange;
  String _selectedCategory = 'All';
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc

  final List<String> _commonCategories = [
    'All',
    'Salary',
    'Freelance',
    'Investments',
    'Rent',
    'Groceries',
    'Utilities & Bills',
    'Shopping',
    'Health',
    'Travel',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _prevPeriod() {
    setState(() {
      if (_filterMode == DateFilterMode.month) {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear -= 1;
        } else {
          _selectedMonth -= 1;
        }
      } else if (_filterMode == DateFilterMode.day) {
        final current = _selectedDay ?? DateTime.now();
        _selectedDay = current.subtract(const Duration(days: 1));
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_filterMode == DateFilterMode.month) {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear += 1;
        } else {
          _selectedMonth += 1;
        }
      } else if (_filterMode == DateFilterMode.day) {
        final current = _selectedDay ?? DateTime.now();
        _selectedDay = current.add(const Duration(days: 1));
      }
    });
  }

  void _resetToCurrentMonth() {
    setState(() {
      _filterMode = DateFilterMode.month;
      _selectedYear = DateTime.now().year;
      _selectedMonth = DateTime.now().month;
      _selectedDay = null;
      _selectedDateRange = null;
      _selectedCategory = 'All';
      _searchController.clear();
    });
  }

  Future<void> _pickSpecificDay() async {
    final initialDate = _selectedDay ?? (_filterMode == DateFilterMode.month
        ? DateTime(_selectedYear, _selectedMonth, 1)
        : DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Select Specific Day',
      confirmText: 'Filter Day',
    );

    if (picked != null) {
      setState(() {
        _filterMode = DateFilterMode.day;
        _selectedDay = picked;
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final initialRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime(_selectedYear, _selectedMonth, 1),
          end: DateTime(_selectedYear, _selectedMonth + 1, 0),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      helpText: 'Select Custom Date Range',
      saveText: 'Apply Range',
    );

    if (picked != null) {
      setState(() {
        _filterMode = DateFilterMode.range;
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _pickMonthYear() async {
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text('Select Month & Year'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Year:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: tempYear,
                        items: List.generate(15, (index) => 2020 + index).map((yr) {
                          return DropdownMenuItem(value: yr, child: Text('$yr'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempYear = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Month:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final m = index + 1;
                      final isSelected = m == tempMonth;
                      final monthName = DateFormat('MMM').format(DateTime(2026, m));
                      return ChoiceChip(
                        label: Text(monthName),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6366F1),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setDialogState(() => tempMonth = m);
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _filterMode = DateFilterMode.month;
                      _selectedYear = tempYear;
                      _selectedMonth = tempMonth;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCalendarFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(100),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction Date Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x206366F1),
                    child: Icon(Icons.today_rounded, color: Color(0xFF6366F1)),
                  ),
                  title: const Text('Today', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormat('dd MMMM yyyy').format(DateTime.now())),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMode = DateFilterMode.day;
                      _selectedDay = DateTime.now();
                      _selectedYear = DateTime.now().year;
                      _selectedMonth = DateTime.now().month;
                    });
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x200EA5E9),
                    child: Icon(Icons.calendar_month_rounded, color: Color(0xFF0EA5E9)),
                  ),
                  title: const Text('Select Month & Year', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View entire monthly transactions & cashflow'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMonthYear();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x2010B981),
                    child: Icon(Icons.event_available_rounded, color: Color(0xFF10B981)),
                  ),
                  title: const Text('Select Specific Day', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pick any single day in calendar'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickSpecificDay();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x20F59E0B),
                    child: Icon(Icons.date_range_rounded, color: Color(0xFFF59E0B)),
                  ),
                  title: const Text('Custom Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Filter transactions between Start and End dates'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDateRange();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x2064748B),
                    child: Icon(Icons.all_inclusive_rounded, color: Color(0xFF64748B)),
                  ),
                  title: const Text('All Time Transactions', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View all transactions without date boundaries'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMode = DateFilterMode.allTime;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSortCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String tempCategory = _selectedCategory;
        String tempSort = _sortBy;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Sort Options'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _commonCategories.map((cat) {
                        final isSel = tempCategory == cat;
                        return ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : null)),
                          selected: isSel,
                          selectedColor: const Color(0xFF6366F1),
                          onSelected: (_) => setDialogState(() => tempCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text('Sort By:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tempSort,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Date: Newest First')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Date: Oldest First')),
                        DropdownMenuItem(value: 'amount_desc', child: Text('Amount: Highest First')),
                        DropdownMenuItem(value: 'amount_asc', child: Text('Amount: Lowest First')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => tempSort = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _sortBy = 'date_desc';
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = tempCategory;
                      _sortBy = tempSort;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getDateHeaderTitle() {
    switch (_filterMode) {
      case DateFilterMode.month:
        return AppDateUtils.formatMonthYear(_selectedYear, _selectedMonth);
      case DateFilterMode.day:
        final d = _selectedDay ?? DateTime.now();
        return DateFormat('EEE, dd MMM yyyy').format(d);
      case DateFilterMode.range:
        if (_selectedDateRange != null) {
          final s = DateFormat('dd MMM yyyy').format(_selectedDateRange!.start);
          final e = DateFormat('dd MMM yyyy').format(_selectedDateRange!.end);
          return '$s - $e';
        }
        return 'Custom Date Range';
      case DateFilterMode.allTime:
        return 'All Time Transactions';
    }
  }

  bool _isFilterActive() {
    return _filterMode != DateFilterMode.month ||
        _selectedCategory != 'All' ||
        _searchController.text.trim().isNotEmpty ||
        _selectedYear != DateTime.now().year ||
        _selectedMonth != DateTime.now().month;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProv = context.watch<TransactionProvider>();
    final auth = context.watch<AuthProvider>();

    final allActiveTxs = txProv.transactions;

    // 1. Date Filtering
    List<TransactionModel> dateFiltered;
    switch (_filterMode) {
      case DateFilterMode.month:
        dateFiltered = allActiveTxs.where((t) {
          return t.dueDate.year == _selectedYear && t.dueDate.month == _selectedMonth;
        }).toList();
        break;
      case DateFilterMode.day:
        final target = _selectedDay ?? DateTime.now();
        dateFiltered = allActiveTxs.where((t) {
          return t.dueDate.year == target.year &&
              t.dueDate.month == target.month &&
              t.dueDate.day == target.day;
        }).toList();
        break;
      case DateFilterMode.range:
        if (_selectedDateRange != null) {
          final start = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23, 59, 59,
          );
          dateFiltered = allActiveTxs.where((t) {
            return (t.dueDate.isAfter(start) || t.dueDate.isAtSameMomentAs(start)) &&
                (t.dueDate.isBefore(end) || t.dueDate.isAtSameMomentAs(end));
          }).toList();
        } else {
          dateFiltered = allActiveTxs;
        }
        break;
      case DateFilterMode.allTime:
        dateFiltered = allActiveTxs;
        break;
    }

    // 2. Category Filtering
    if (_selectedCategory != 'All') {
      dateFiltered = dateFiltered.where((t) => (t.category ?? 'General') == _selectedCategory).toList();
    }

    // 3. Search Query Filtering
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      dateFiltered = dateFiltered.where((t) {
        return t.title.toLowerCase().contains(query) ||
            (t.category ?? '').toLowerCase().contains(query) ||
            (t.notes ?? '').toLowerCase().contains(query);
      }).toList();
    }

    // 4. Sorting
    switch (_sortBy) {
      case 'date_asc':
        dateFiltered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'amount_desc':
        dateFiltered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        dateFiltered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'date_desc':
      default:
        dateFiltered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
    }

    final credits = dateFiltered.where((t) => t.type == 'CREDIT').toList();
    final debits = dateFiltered.where((t) => t.type == 'DEBIT').toList();

    // 5. Dynamic calculations based on the filtered set
    final totalCredit = credits.fold(0.0, (sum, t) => sum + t.amount);
    final totalDebit = debits.fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalCredit - totalDebit;

    final userInitial = (auth.currentUser?.name.isNotEmpty == true)
        ? auth.currentUser!.name[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Credit & Debit'),
        actions: [
          IconButton(
            tooltip: 'View Trash',
            icon: Badge(
              isLabelVisible: txProv.deletedTransactions.isNotEmpty,
              label: Text('${txProv.deletedTransactions.length}'),
              child: const Icon(Icons.delete_outline_rounded),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),
          IconButton(
            tooltip: 'Profile & Account',
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                userInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          tabs: [
            Tab(text: 'All (${dateFiltered.length})'),
            Tab(text: 'Credits (+${CurrencyFormatter.format(totalCredit)})'),
            Tab(text: 'Debits (-${CurrencyFormatter.format(totalDebit)})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_tx',
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
      ),
      body: Column(
        children: [
          // 1. Interactive Date Bar with Calendar Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_filterMode == DateFilterMode.month || _filterMode == DateFilterMode.day)
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: _filterMode == DateFilterMode.month ? 'Previous Month' : 'Previous Day',
                    onPressed: _prevPeriod,
                  )
                else
                  const SizedBox(width: 8),

                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _showCalendarFilterSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _getDateHeaderTitle(),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_filterMode == DateFilterMode.month || _filterMode == DateFilterMode.day)
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: _filterMode == DateFilterMode.month ? 'Next Month' : 'Next Day',
                    onPressed: _nextPeriod,
                  )
                else
                  const SizedBox(width: 8),

                // Calendar Icon Button to pick specific day, month, or range
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1)),
                    tooltip: 'Date & Calendar Filters',
                    onPressed: _showCalendarFilterSheet,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: (_selectedCategory != 'All' || _sortBy != 'date_desc')
                        ? const Color(0xFF6366F1)
                        : Colors.grey,
                  ),
                  tooltip: 'Category & Sorting Filters',
                  onPressed: _showSortCategoryDialog,
                ),
              ],
            ),
          ),

          // 2. Quick Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('This Month'),
                  selected: _filterMode == DateFilterMode.month &&
                      _selectedYear == DateTime.now().year &&
                      _selectedMonth == DateTime.now().month,
                  onSelected: (_) => _resetToCurrentMonth(),
                  selectedColor: const Color(0xFF6366F1).withAlpha(40),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Today'),
                  selected: _filterMode == DateFilterMode.day &&
                      _selectedDay?.year == DateTime.now().year &&
                      _selectedDay?.month == DateTime.now().month &&
                      _selectedDay?.day == DateTime.now().day,
                  onSelected: (_) {
                    setState(() {
                      _filterMode = DateFilterMode.day;
                      _selectedDay = DateTime.now();
                    });
                  },
                  selectedColor: const Color(0xFF6366F1).withAlpha(40),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.event_rounded, size: 16, color: Color(0xFF6366F1)),
                  label: Text(_filterMode == DateFilterMode.day && _selectedDay != null
                      ? DateFormat('dd MMM').format(_selectedDay!)
                      : 'Pick Day'),
                  backgroundColor: _filterMode == DateFilterMode.day ? const Color(0xFF6366F1).withAlpha(40) : null,
                  onPressed: _pickSpecificDay,
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFFF59E0B)),
                  label: Text(_filterMode == DateFilterMode.range && _selectedDateRange != null
                      ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                      : 'Date Range'),
                  backgroundColor: _filterMode == DateFilterMode.range ? const Color(0xFFF59E0B).withAlpha(40) : null,
                  onPressed: _pickDateRange,
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.all_inclusive_rounded, size: 16, color: Color(0xFF64748B)),
                  label: const Text('All Time'),
                  backgroundColor: _filterMode == DateFilterMode.allTime ? const Color(0xFF64748B).withAlpha(40) : null,
                  onPressed: () {
                    setState(() => _filterMode = DateFilterMode.allTime);
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: Icon(
                    Icons.category_rounded,
                    size: 16,
                    color: _selectedCategory != 'All' ? const Color(0xFF10B981) : Colors.grey,
                  ),
                  label: Text(_selectedCategory == 'All' ? 'Category' : _selectedCategory),
                  backgroundColor: _selectedCategory != 'All' ? const Color(0xFF10B981).withAlpha(40) : null,
                  onPressed: _showSortCategoryDialog,
                ),
              ],
            ),
          ),

          // 3. Active Filter Badge & Reset Banner (if custom filter applied)
          if (_isFilterActive())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Filtered by: ${_getDateHeaderTitle()}${_selectedCategory != 'All' ? ' | $_selectedCategory' : ''}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFF43F5E)),
                    label: const Text('Reset', style: TextStyle(fontSize: 11, color: Color(0xFFF43F5E))),
                    onPressed: _resetToCurrentMonth,
                  ),
                ],
              ),
            ),

          // 4. Monthly/Filtered Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('Total Credit', CurrencyFormatter.format(totalCredit), const Color(0xFF10B981)),
                Container(height: 24, width: 1, color: Colors.grey.withAlpha(80)),
                _summaryItem('Total Debit', CurrencyFormatter.format(totalDebit), const Color(0xFFF43F5E)),
                Container(height: 24, width: 1, color: Colors.grey.withAlpha(80)),
                _summaryItem(
                  'Net Balance',
                  CurrencyFormatter.format(netBalance),
                  netBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                ),
              ],
            ),
          ),

          // 5. Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search salary, rent, bills...',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // 6. Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTxList(context, dateFiltered, isDark),
                _buildTxList(context, credits, isDark),
                _buildTxList(context, debits, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTxList(BuildContext context, List<TransactionModel> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.withAlpha(120)),
            const SizedBox(height: 12),
            const Text(
              'No transactions found for this selection.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (_isFilterActive())
              OutlinedButton.icon(
                onPressed: _resetToCurrentMonth,
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Reset All Filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final tx = items[index];
        final isCredit = tx.type == 'CREDIT';
        final color = isCredit ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(25),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    tx.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (tx.isRecurring)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat_rounded, size: 11, color: Color(0xFF6366F1)),
                        SizedBox(width: 3),
                        Text(
                          'Recurring',
                          style: TextStyle(fontSize: 10, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (tx.category != null) ...[
                      Text(
                        tx.category!,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                    ],
                    Text(
                      AppDateUtils.formatDayMonth(tx.dueDate),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (tx.notes != null && tx.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tx.notes!,
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isCredit ? "+" : "-"}${CurrencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                  tooltip: 'Move to Trash',
                  onPressed: () async {
                    await context.read<TransactionProvider>().softDeleteTransaction(tx.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${tx.title}" moved to Trash.'),
                          action: SnackBarAction(
                            label: 'Undo',
                            textColor: Colors.amber,
                            onPressed: () {
                              context.read<TransactionProvider>().restoreTransaction(tx.id);
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
