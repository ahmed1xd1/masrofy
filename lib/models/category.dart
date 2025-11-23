import 'package:flutter/material.dart';

class Category {
  final String id;
  String name;
  String icon;
  Color color;
  bool isFixed; // true = Fixed (Bills), false = Variable (Daily)
  double? budgetLimit;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isFixed = false,
    this.budgetLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.toARGB32(),
      'isFixed': isFixed,
      'budgetLimit': budgetLimit,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: Color(json['color']),
      isFixed: json['isFixed'] ?? false,
      budgetLimit: json['budgetLimit'],
    );
  }
}
