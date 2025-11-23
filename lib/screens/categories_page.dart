import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/category.dart';

class CategoriesPage extends StatefulWidget {
  final List<Category> categories;
  final Function(Category) onAdd;
  final Function(Category) onUpdate;
  final Function(String) onDelete;

  const CategoriesPage({
    super.key,
    required this.categories,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '🏷️');
    final limitController = TextEditingController(
      text: category?.budgetLimit?.toString() ?? '',
    );
    bool isFixed = category?.isFixed ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(isEditing ? 'تعديل التصنيف' : 'إضافة تصنيف جديد'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم التصنيف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: iconController,
                      decoration: InputDecoration(
                        labelText: 'الأيقونة (مثل: 🏠)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'حد الميزانية (اختياري)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SwitchListTile(
                      title: Text('مصاريف ثابتة؟'),
                      subtitle: Text(
                        isFixed
                            ? 'مثل: إيجار، إنترنت، كهرباء'
                            : 'مثل: طعام، مواصلات، ترفيه',
                      ),
                      value: isFixed,
                      onChanged: (value) {
                        setState(() {
                          isFixed = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final newCategory = Category(
                        id: isEditing ? category.id : DateTime.now().toString(),
                        name: nameController.text,
                        icon: iconController.text,
                        color: isEditing
                            ? category.color
                            : Color(
                                (math.Random().nextDouble() * 0xFFFFFF).toInt(),
                              ).withValues(alpha: 1.0),
                        isFixed: isFixed,
                        budgetLimit: double.tryParse(limitController.text),
                      );

                      if (isEditing) {
                        widget.onUpdate(newCategory);
                      } else {
                        widget.onAdd(newCategory);
                      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة التصنيفات')),
      body: widget.categories.isEmpty
          ? Center(child: Text('لا توجد تصنيفات. أضف تصنيفك الأول!'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final cat = widget.categories[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(cat.icon, style: TextStyle(fontSize: 24)),
                    ),
                    title: Text(
                      cat.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.isFixed ? 'مصروف ثابت' : 'مصروف متغير'),
                        if (cat.budgetLimit != null)
                          Text(
                            'الحد: ${cat.budgetLimit!.toStringAsFixed(0)} جنيه',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showCategoryDialog(category: cat),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => widget.onDelete(cat.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
