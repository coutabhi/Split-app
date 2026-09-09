import 'package:flutter/material.dart';

import '../models/expense.dart';

IconData categoryIcon(ExpenseCategory c) {
  switch (c) {
    case ExpenseCategory.food:
      return Icons.restaurant;
    case ExpenseCategory.transport:
      return Icons.directions_car_filled;
    case ExpenseCategory.entertainment:
      return Icons.local_movies;
    case ExpenseCategory.home:
      return Icons.home;
    case ExpenseCategory.utilities:
      return Icons.bolt;
    case ExpenseCategory.shopping:
      return Icons.shopping_bag;
    case ExpenseCategory.travel:
      return Icons.flight;
    case ExpenseCategory.general:
      return Icons.receipt_long;
  }
}

String categoryLabel(ExpenseCategory c) {
  switch (c) {
    case ExpenseCategory.food:
      return 'Food & drink';
    case ExpenseCategory.transport:
      return 'Transport';
    case ExpenseCategory.entertainment:
      return 'Entertainment';
    case ExpenseCategory.home:
      return 'Home';
    case ExpenseCategory.utilities:
      return 'Utilities';
    case ExpenseCategory.shopping:
      return 'Shopping';
    case ExpenseCategory.travel:
      return 'Travel';
    case ExpenseCategory.general:
      return 'General';
  }
}
