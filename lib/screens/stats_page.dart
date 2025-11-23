import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';

class StatsPage extends StatelessWidget {
  final double monthlyBudget;
  final int planDuration;
  final List<Expense> expenses;
  final List<dynamic>
  categories; // Using dynamic to avoid import loop if model not imported, but better to import

  const StatsPage({
    super.key,
    required this.monthlyBudget,
    required this.planDuration,
    required this.expenses,
    required this.categories,
  });

  double get totalExpenses => expenses.fold(0, (sum, exp) => sum + exp.amount);
  double get savings => monthlyBudget - totalExpenses;
  double get dailyBudget => monthlyBudget / planDuration;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatisticsCards(context),
          SizedBox(height: 16),
          _buildCategoryBudgets(context),
          SizedBox(height: 16),
          _buildPieChart(context),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context) {
    final daysPassed = DateTime.now().day;
    final dailyAverage = totalExpenses / (daysPassed == 0 ? 1 : daysPassed);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'إجمالي المصروفات',
                '${totalExpenses.toStringAsFixed(0)} جنيه',
                Color(0xFFEF4444),
                Icons.trending_down,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'المبلغ المتبقي',
                '${(monthlyBudget - totalExpenses).toStringAsFixed(0)} جنيه',
                Color(0xFF6B7280),
                Icons.account_balance,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'التوفير',
                '${savings.toStringAsFixed(0)} جنيه',
                Color(0xFF10B981),
                Icons.savings,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'متوسط الصرف اليومي',
                '${dailyAverage.toStringAsFixed(0)} جنيه/يوم',
                Color(0xFF3B82F6),
                Icons.calendar_today,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    if (expenses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(child: Text('لا توجد بيانات للعرض')),
      );
    }

    // Calculate category totals for better visualization
    final categoryTotals = <String, double>{};
    final categoryColors = <String, Color>{};
    final categoryIcons = <String, String>{};

    for (var exp in expenses) {
      categoryTotals[exp.category] =
          (categoryTotals[exp.category] ?? 0) + exp.amount;
      categoryColors[exp.category] = exp.color;
      categoryIcons[exp.category] = exp.icon;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع المصروفات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: categoryTotals.entries.map((entry) {
                  return PieChartSectionData(
                    color: categoryColors[entry.key],
                    value: entry.value,
                    title:
                        '${((entry.value / totalExpenses) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 20),
          ...categoryTotals.entries.map((entry) {
            final categoryName = entry.key;
            final amount = entry.value;
            final color = categoryColors[categoryName]!;
            final icon = categoryIcons[categoryName]!;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$icon $categoryName',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    '${amount.toStringAsFixed(0)} جنيه',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgets(BuildContext context) {
    // Filter categories with limits
    final budgetedCategories = categories
        .where((c) => c.budgetLimit != null)
        .toList();

    if (budgetedCategories.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ميزانيات التصنيفات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ...budgetedCategories.map((category) {
            final totalSpent = expenses
                .where((e) => e.categoryId == category.id)
                .fold(0.0, (sum, e) => sum + e.amount);
            final limit = category.budgetLimit!;
            final progress = (totalSpent / limit).clamp(0.0, 1.0);
            final isExceeded = totalSpent > limit;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(category.icon),
                          SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                      Text(
                        '${totalSpent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isExceeded ? Colors.red : Colors.grey[600],
                          fontWeight: isExceeded
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isExceeded
                            ? Colors.red
                            : (progress > 0.9 ? Colors.orange : category.color),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
