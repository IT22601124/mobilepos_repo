import 'package:flutter/material.dart';

class CreditCustomerList extends StatelessWidget {
  const CreditCustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final customers = [];

    return Column(
      children: customers.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item[0],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      item[1],
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Limit ${item[2]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                  ),
                  Text(
                    item[3],
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return BoxDecoration(
    color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFEAF1FB),
    borderRadius: BorderRadius.circular(8),
    border: isDark ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)) : null,
  );
}
