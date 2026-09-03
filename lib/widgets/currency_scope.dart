import 'package:flutter/material.dart';

/// Makes the team's chosen currency symbol available to the whole widget
/// tree without threading it through every constructor.
class CurrencyScope extends InheritedWidget {
  const CurrencyScope({
    super.key,
    required this.symbol,
    required this.setSymbol,
    required super.child,
  });

  final String symbol;
  final ValueChanged<String> setSymbol;

  static CurrencyScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurrencyScope>();
    assert(scope != null, 'CurrencyScope not found in context');
    return scope!;
  }

  String format(num amount) => '$symbol${amount.toStringAsFixed(2)}';

  @override
  bool updateShouldNotify(CurrencyScope oldWidget) => oldWidget.symbol != symbol;
}
