import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../models/expense.dart';

class ExpensesPage extends StatefulWidget {
  final List<Expense> expenses;
  final double totalExpenses;
  final Function(Expense) onEdit;
  final Function(String) onDelete;

  const ExpensesPage({
    super.key,
    required this.expenses,
    required this.totalExpenses,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> get _filteredExpenses {
    if (_searchQuery.isEmpty) {
      return widget.expenses;
    }
    return widget.expenses.where((exp) {
      final query = _searchQuery.toLowerCase();
      final categoryMatch = exp.category.toLowerCase().contains(query);
      final noteMatch = exp.note?.toLowerCase().contains(query) ?? false;
      final amountMatch = exp.amount.toString().contains(query);
      return categoryMatch || noteMatch || amountMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredExpenses;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إدارة المصروفات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث (التصنيف، الملاحظة، المبلغ)...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 16),
          if (filteredList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  widget.expenses.isEmpty
                      ? 'لا توجد مصروفات. أضف مصروفك الأول!'
                      : 'لا توجد نتائج مطابقة للبحث.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...filteredList.map((exp) => _buildExpenseItem(context, exp)),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense exp) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: exp.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(exp.icon, style: TextStyle(fontSize: 24)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        intl.DateFormat('d/M/y h:mm a').format(exp.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (exp.note != null && exp.note!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          exp.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                '${exp.amount.toStringAsFixed(0)} جنيه',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: exp.color,
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                onPressed: () => widget.onEdit(exp),
                icon: Icon(Icons.edit, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[700],
                  padding: EdgeInsets.all(8),
                ),
              ),
              SizedBox(width: 4),
              IconButton(
                onPressed: () => widget.onDelete(exp.id),
                icon: Icon(Icons.delete, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[700],
                  padding: EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
