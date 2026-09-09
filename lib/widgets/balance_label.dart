import 'package:flutter/material.dart';

import 'currency_scope.dart';

const Color kOwedColor = Color(0xFF2E9E5B);

/// Splitwise-style "owes you $X" / "you owe $X" / "settled up" label.
/// [amount] positive means the other side owes you; negative means you owe
/// them.
class BalanceLabel extends StatelessWidget {
  const BalanceLabel({
    super.key,
    required this.amount,
    this.large = false,
    this.otherName,
    this.align = CrossAxisAlignment.end,
  });

  final double amount;
  final bool large;
  final String? otherName;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final settled = amount.abs() < 0.005;
    final owed = amount > 0;
    final color = settled ? scheme.onSurfaceVariant : (owed ? kOwedColor : scheme.error);

    final amountStyle = TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      fontSize: large ? 22 : 14,
    );
    final captionStyle = TextStyle(
      color: settled ? scheme.onSurfaceVariant : color,
      fontSize: large ? 13 : 11,
      fontWeight: FontWeight.w600,
    );

    if (settled) {
      return Text('settled up', style: captionStyle);
    }

    final caption = owed
        ? (otherName != null ? '$otherName owes you' : 'you are owed')
        : (otherName != null ? 'you owe $otherName' : 'you owe');

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(currency.format(amount.abs()), style: amountStyle),
        Text(caption, style: captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
