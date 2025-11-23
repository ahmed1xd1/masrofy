import 'package:flutter/material.dart';

class Expense {
  final String id;
  String category; // Keeping for backward compatibility/display
  String? categoryId; // Link to Category model
  double amount;
  Color color;
  String icon;

  DateTime date;
  String? note;

  Expense({
    required this.id,
    required this.category,
    this.categoryId,
    required this.amount,
    required this.date,
    required this.color,
    required this.icon,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'categoryId': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'color': color.toARGB32(),
      'icon': icon,
      'note': note,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      category: json['category'],
      categoryId: json['categoryId'],
      amount: json['amount'],
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.tryParse(json['id']) ??
                DateTime.now(), // Fallback to ID (if it's a date) or Now
      color: Color(json['color']),
      icon: json['icon'],
      note: json['note'],
    );
  }
}
