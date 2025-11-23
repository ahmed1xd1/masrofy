import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final double monthlyBudget;
  final int planDuration;
  final ValueChanged<double> onBudgetChanged;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onManageCategories;
  final VoidCallback onExportData;
  final VoidCallback onImportData;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.monthlyBudget,
    required this.planDuration,
    required this.onBudgetChanged,
    required this.onDurationChanged,
    required this.onManageCategories,
    required this.onExportData,
    required this.onImportData,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.planStartDate,
    required this.onStartDateChanged,
    required this.savingsGoal,
    required this.onSavingsGoalChanged,
  });

  final DateTime planStartDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final double savingsGoal;
  final ValueChanged<double> onSavingsGoalChanged;

  @override
  Widget build(BuildContext context) {
    final budgetController = TextEditingController(
      text: monthlyBudget.toString(),
    );
    final durationController = TextEditingController(
      text: planDuration.toString(),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          _buildSectionTitle(context, 'الميزانية والخطط'),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الميزانية الشهرية',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        onBudgetChanged(double.parse(value));
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'مدة الخطة (أيام)',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        onDurationChanged(int.parse(value));
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(
                      text: savingsGoal > 0
                          ? savingsGoal.toStringAsFixed(0)
                          : '',
                    ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'هدف التوفير (اختياري)',
                      prefixIcon: Icon(Icons.savings),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'اترك فارغاً إذا لم يكن لديك هدف',
                    ),
                    onSubmitted: (value) {
                      if (value.isEmpty) {
                        onSavingsGoalChanged(0);
                      } else {
                        onSavingsGoalChanged(double.parse(value));
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text('تاريخ بدء الخطة'),
                    subtitle: Text(
                      '${planStartDate.day}/${planStartDate.month}/${planStartDate.year}',
                    ),
                    leading: Icon(Icons.date_range, color: Colors.purple),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: planStartDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        onStartDateChanged(picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          _buildSectionTitle(context, 'المظهر'),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              title: Text('الوضع الليلي'),
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: isDarkMode ? Colors.white : Colors.orange,
              ),
              value: isDarkMode,
              onChanged: onThemeChanged,
            ),
          ),
          SizedBox(height: 24),
          _buildSectionTitle(context, 'إدارة التطبيق'),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.category, color: Colors.blue),
                  title: Text('إدارة التصنيفات'),
                  subtitle: Text('إضافة، تعديل، وحذف التصنيفات'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: onManageCategories,
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.upload, color: Colors.green),
                  title: Text('تصدير البيانات (نسخ)'),
                  subtitle: Text('نسخ البيانات للحافظة'),
                  trailing: Icon(Icons.copy, size: 16),
                  onTap: onExportData,
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.orange),
                  title: Text('استيراد البيانات (لصق)'),
                  subtitle: Text('استعادة البيانات من الحافظة'),
                  trailing: Icon(Icons.paste, size: 16),
                  onTap: onImportData,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[700],
      ),
    );
  }
}
