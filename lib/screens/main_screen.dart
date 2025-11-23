import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:convert';
import '../models/expense.dart';
import '../models/category.dart';
import 'home_page.dart';
import 'stats_page.dart';
import 'expenses_page.dart';
import 'settings_page.dart';
import 'categories_page.dart';

class MainScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double monthlyBudget = 5000;
  int planDuration = 30;
  List<Expense> expenses = [];
  List<Category> categories = [];
  DateTime _selectedMonth = DateTime.now();
  DateTime planStartDate = DateTime.now();
  double savingsGoal = 0;

  List<DateTime> get _availableMonths {
    final months = <DateTime>{};
    // Always include current month
    final now = DateTime.now();
    months.add(DateTime(now.year, now.month));

    for (var exp in expenses) {
      months.add(DateTime(exp.date.year, exp.date.month));
    }

    final sorted = months.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first
    return sorted;
  }

  List<Expense> get _filteredExpenses {
    return expenses.where((exp) {
      return exp.date.year == _selectedMonth.year &&
          exp.date.month == _selectedMonth.month;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      monthlyBudget = prefs.getDouble('monthlyBudget') ?? 5000;
      planDuration = prefs.getInt('planDuration') ?? 30;
      savingsGoal = prefs.getDouble('savingsGoal') ?? 0;
      final startDateStr = prefs.getString('planStartDate');
      planStartDate = startDateStr != null
          ? DateTime.parse(startDateStr)
          : DateTime.now();

      // Load Categories
      final categoriesJson = prefs.getStringList('categories');
      if (categoriesJson != null) {
        categories = categoriesJson
            .map((c) => Category.fromJson(json.decode(c)))
            .toList();
      } else {
        // Default Categories
        categories = [
          Category(
            id: '1',
            name: 'طعام',
            icon: '🍽️',
            color: Color(0xFFEF4444),
            isFixed: false,
          ),
          Category(
            id: '2',
            name: 'مواصلات',
            icon: '🚗',
            color: Color(0xFFF59E0B),
            isFixed: false,
          ),
          Category(
            id: '3',
            name: 'كهرباء',
            icon: '⚡',
            color: Color(0xFF3B82F6),
            isFixed: true,
          ),
          Category(
            id: '4',
            name: 'مياه',
            icon: '💧',
            color: Color(0xFF10B981),
            isFixed: true,
          ),
          Category(
            id: '5',
            name: 'إيجار',
            icon: '🏠',
            color: Color(0xFF8B5CF6),
            isFixed: true,
          ),
          Category(
            id: '6',
            name: 'ترفيه',
            icon: '🎮',
            color: Color(0xFFEC4899),
            isFixed: false,
          ),
        ];
      }

      // Load Expenses
      final expensesJson = prefs.getStringList('expenses');
      if (expensesJson != null) {
        expenses = expensesJson
            .map((e) => Expense.fromJson(json.decode(e)))
            .toList();
      }
    });
    await _checkRecurringExpenses(prefs);
    _checkPlanStatus(prefs);
  }

  void _checkPlanStatus(SharedPreferences prefs) {
    final planEndDate = planStartDate.add(Duration(days: planDuration));
    final now = DateTime.now();
    final lastReportDateStr = prefs.getString('lastReportDate');
    final lastReportDate = lastReportDateStr != null
        ? DateTime.parse(lastReportDateStr)
        : null;

    if (now.isAfter(planEndDate)) {
      // Check if we already showed the report for this plan cycle
      if (lastReportDate == null || lastReportDate.isBefore(planEndDate)) {
        // Show Report
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showEndOfPlanReport();
          prefs.setString('lastReportDate', now.toIso8601String());
        });
      }
    }
  }

  void _showEndOfPlanReport() {
    final planEndDate = planStartDate.add(Duration(days: planDuration));
    final expensesInPlan = expenses.where((e) {
      return e.date.isAfter(planStartDate) && e.date.isBefore(planEndDate);
    }).toList();

    final totalSpent = expensesInPlan.fold(0.0, (sum, e) => sum + e.amount);
    final savings = monthlyBudget - totalSpent;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تقرير انتهاء الخطة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('انتهت خطة الـ $planDuration يوم!'),
              SizedBox(height: 16),
              ListTile(
                title: Text('الميزانية: $monthlyBudget'),
                leading: Icon(Icons.account_balance_wallet, color: Colors.blue),
              ),
              ListTile(
                title: Text('المصروفات: $totalSpent'),
                leading: Icon(Icons.money_off, color: Colors.red),
              ),
              ListTile(
                title: Text('التوفير: $savings'),
                leading: Icon(
                  Icons.savings,
                  color: savings >= 0 ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(height: 16),
              Text(
                savings >= 0
                    ? 'عمل رائع! لقد وفرت المال.'
                    : 'لقد تجاوزت الميزانية، حظاً أوفر المرة القادمة.',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkRecurringExpenses(SharedPreferences prefs) async {
    final lastRunStr = prefs.getString('lastRecurringRun');
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    DateTime? lastRun;
    if (lastRunStr != null) {
      lastRun = DateTime.parse(lastRunStr);
    }

    // If never run, or last run was in a previous month
    if (lastRun == null ||
        currentMonth.isAfter(DateTime(lastRun.year, lastRun.month))) {
      bool addedAny = false;

      for (var category in categories) {
        if (category.isFixed) {
          // Check if we already have an expense for this fixed category in this month
          final alreadyExists = expenses.any(
            (e) =>
                e.categoryId == category.id &&
                e.date.year == currentMonth.year &&
                e.date.month == currentMonth.month &&
                (e.note?.contains('Auto-added') ?? false),
          );

          if (!alreadyExists) {
            final amount = category.budgetLimit ?? 0.0;
            expenses.add(
              Expense(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    category.id, // Unique ID
                category: category.name,
                categoryId: category.id,
                amount: amount,
                date: currentMonth, // First day of the month
                color: category.color,
                icon: category.icon,
                note: 'Auto-added (Recurring)',
              ),
            );
            addedAny = true;
          }
        }
      }

      if (addedAny) {
        _saveData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إضافة المصروفات الثابتة لهذا الشهر تلقائياً'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Update last run time
      await prefs.setString('lastRecurringRun', currentMonth.toIso8601String());
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', monthlyBudget);
    await prefs.setInt('planDuration', planDuration);
    await prefs.setDouble('savingsGoal', savingsGoal);
    await prefs.setString('planStartDate', planStartDate.toIso8601String());

    final expensesJson = expenses.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('expenses', expensesJson);

    final categoriesJson = categories
        .map((c) => json.encode(c.toJson()))
        .toList();
    await prefs.setStringList('categories', categoriesJson);
  }

  Future<void> _exportData() async {
    final data = {
      'monthlyBudget': monthlyBudget,
      'planDuration': planDuration,
      'savingsGoal': savingsGoal,
      'planStartDate': planStartDate.toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
    final jsonString = json.encode(data);
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم نسخ البيانات إلى الحافظة بنجاح!')),
      );
    }
  }

  Future<void> _importData() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('الحافظة فارغة!')));
      }
      return;
    }

    if (!mounted) return;

    try {
      final jsonMap = json.decode(data!.text!) as Map<String, dynamic>;

      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تأكيد الاستيراد'),
            content: Text(
              'سيتم استبدال جميع البيانات الحالية بالبيانات المنسوخة.\\n'
              'هل أنت متأكد؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    monthlyBudget = (jsonMap['monthlyBudget'] as num)
                        .toDouble();
                    planDuration = jsonMap['planDuration'] as int;
                    savingsGoal =
                        (jsonMap['savingsGoal'] as num?)?.toDouble() ?? 0;
                    if (jsonMap['planStartDate'] != null) {
                      planStartDate = DateTime.parse(jsonMap['planStartDate']);
                    }

                    if (jsonMap['categories'] != null) {
                      categories = (jsonMap['categories'] as List)
                          .map((c) => Category.fromJson(c))
                          .toList();
                    }

                    if (jsonMap['expenses'] != null) {
                      expenses = (jsonMap['expenses'] as List)
                          .map((e) => Expense.fromJson(e))
                          .toList();
                    }

                    _saveData();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم استعادة البيانات بنجاح!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('استبدال البيانات'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في قراءة البيانات: تأكد من نسخ كود صحيح'),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _deleteExpense(String id) {
    setState(() {
      expenses.removeWhere((exp) => exp.id == id);
      _saveData();
    });
  }

  void _addCategory(Category category) {
    setState(() {
      categories.add(category);
      _saveData();
    });
  }

  void _updateCategory(Category category) {
    setState(() {
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category;
        _saveData();
      }
    });
  }

  void _deleteCategory(String id) {
    setState(() {
      categories.removeWhere((c) => c.id == id);
      _saveData();
    });
  }

  void _showAddExpenseDialog({Expense? expense}) {
    final isEditing = expense != null;
    final amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    DateTime selectedDate = expense?.date ?? DateTime.now();

    // Find initial category
    Category? selectedCategory;
    if (isEditing && expense.categoryId != null) {
      selectedCategory = categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => categories.first,
      );
    } else if (isEditing) {
      // Try to match by name for old data
      try {
        selectedCategory = categories.firstWhere(
          (c) => c.name == expense.category,
        );
      } catch (e) {
        selectedCategory = categories.isNotEmpty ? categories.first : null;
      }
    } else {
      selectedCategory = categories.isNotEmpty ? categories.first : null;
    }

    final noteController = TextEditingController(text: expense?.note ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(isEditing ? 'تعديل المصروف' : 'إضافة مصروف جديد'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (categories.isEmpty)
                    Text('يرجى إضافة تصنيفات أولاً من الإعدادات')
                  else
                    DropdownButtonFormField<Category>(
                      // ignore: deprecated_member_use
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: categories.map((Category category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Text(category.icon),
                              SizedBox(width: 8),
                              Text(category.name),
                              if (category.isFixed) ...[
                                SizedBox(width: 4),
                                Icon(Icons.lock, size: 14, color: Colors.grey),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Category? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                  SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        if (!context.mounted) return;
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'التاريخ والوقت',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        intl.DateFormat('d/M/y h:mm a').format(selectedDate),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedCategory != null &&
                        amountController.text.isNotEmpty) {
                      final amount = double.parse(amountController.text);

                      // Check Budget Limit
                      if (selectedCategory!.budgetLimit != null) {
                        final currentTotal = expenses
                            .where((e) => e.categoryId == selectedCategory!.id)
                            .fold(0.0, (sum, e) => sum + e.amount);

                        // If editing, subtract old amount
                        final adjustedTotal = isEditing
                            ? currentTotal - expense.amount
                            : currentTotal;

                        final newTotal = adjustedTotal + amount;
                        final limit = selectedCategory!.budgetLimit!;

                        if (newTotal > limit) {
                          // Show Error: Exceeding Limit
                          showDialog(
                            context: context,
                            builder: (context) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: Text('تحذير: تجاوز الميزانية!'),
                                content: Text(
                                  'أنت على وشك تجاوز الحد المسموح به لتصنيف "${selectedCategory!.name}".\\n'
                                  'الحد: $limit جنيه\\n'
                                  'المصروف الحالي: $adjustedTotal جنيه\\n'
                                  'المبلغ الجديد: $amount جنيه',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close warning
                                      _saveExpense(
                                        isEditing,
                                        expense,
                                        selectedCategory!,
                                        amount,
                                        selectedDate,
                                        noteController.text,
                                      );
                                      Navigator.pop(
                                        context,
                                      ); // Close add dialog
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('تجاهل وإضافة'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          return;
                        } else if (newTotal >= limit * 0.9) {
                          // Show Warning: Approaching Limit (90%)
                          showDialog(
                            context: context,
                            builder: (context) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: Text('تنبيه: اقتراب من الحد'),
                                content: Text(
                                  'لقد وصلت إلى 90% من ميزانية تصنيف "${selectedCategory!.name}".\\n'
                                  'الحد: $limit جنيه\\n'
                                  'الإجمالي بعد الإضافة: $newTotal جنيه',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close warning
                                      _saveExpense(
                                        isEditing,
                                        expense,
                                        selectedCategory!,
                                        amount,
                                        selectedDate,
                                        noteController.text,
                                      );
                                      Navigator.pop(
                                        context,
                                      ); // Close add dialog
                                    },
                                    child: Text('متابعة'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      _saveExpense(
                        isEditing,
                        expense,
                        selectedCategory!,
                        amount,
                        selectedDate,
                        noteController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'تحديث' : 'إضافة'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveExpense(
    bool isEditing,
    Expense? expense,
    Category category,
    double amount,
    DateTime date,
    String? note,
  ) {
    setState(() {
      if (isEditing) {
        expense!.category = category.name;
        expense.categoryId = category.id;
        expense.amount = amount;
        expense.date = date;
        expense.note = note;
        expense.icon = category.icon;
        expense.color = category.color;
      } else {
        expenses.add(
          Expense(
            id: DateTime.now().toString(),
            category: category.name,
            categoryId: category.id,
            amount: amount,
            date: date,
            note: note,
            color: category.color,
            icon: category.icon,
          ),
        );
      }
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _filteredExpenses;
    final totalFilteredExpenses = filteredExpenses.fold(
      0.0,
      (sum, exp) => sum + exp.amount,
    );

    final List<Widget> pages = [
      HomePage(
        monthlyBudget: monthlyBudget,
        expenses: filteredExpenses,
        planStartDate: planStartDate,
        planDuration: planDuration,
        savingsGoal: savingsGoal,
      ),
      StatsPage(
        monthlyBudget: monthlyBudget,
        planDuration: planDuration,
        expenses: filteredExpenses,
        categories: categories,
      ),
      ExpensesPage(
        expenses: filteredExpenses,
        totalExpenses: totalFilteredExpenses,
        onEdit: (exp) => _showAddExpenseDialog(expense: exp),
        onDelete: _deleteExpense,
      ),
      SettingsPage(
        monthlyBudget: monthlyBudget,
        planDuration: planDuration,
        planStartDate: planStartDate,
        onBudgetChanged: (value) {
          setState(() {
            monthlyBudget = value;
            _saveData();
          });
        },
        onDurationChanged: (value) {
          setState(() {
            planDuration = value;
            _saveData();
          });
        },
        onStartDateChanged: (value) {
          setState(() {
            planStartDate = value;
            _saveData();
          });
        },
        savingsGoal: savingsGoal,
        onSavingsGoalChanged: (value) {
          setState(() {
            savingsGoal = value;
            _saveData();
          });
        },
        onManageCategories: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoriesPage(
                categories: categories,
                onAdd: _addCategory,
                onUpdate: _updateCategory,
                onDelete: _deleteCategory,
              ),
            ),
          );
        },
        onExportData: _exportData,
        onImportData: _importData,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, color: Colors.white),
              SizedBox(width: 8),
              DropdownButton<DateTime>(
                value: _availableMonths.contains(_selectedMonth)
                    ? _selectedMonth
                    : _availableMonths.first,
                dropdownColor: widget.isDarkMode ? Color(0xFF1E1E1E) : null,
                underline: Container(),
                items: _availableMonths.map((DateTime date) {
                  return DropdownMenuItem<DateTime>(
                    value: date,
                    child: Text(
                      '${_getMonthName(date.month)} ${date.year}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (DateTime? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMonth = newValue;
                    });
                  }
                },
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: widget.isDarkMode
              ? Color(0xFF1F2937)
              : Color(0xFF1E40AF),
          elevation: 0,
        ),
        body: SafeArea(child: pages[_selectedIndex]),
        floatingActionButton: _selectedIndex == 0 || _selectedIndex == 2
            ? FloatingActionButton(
                onPressed: () => _showAddExpenseDialog(),
                child: Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'الإحصائيات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'المصروفات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }
}
