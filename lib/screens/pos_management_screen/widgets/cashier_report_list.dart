import 'package:flutter/material.dart';

class CashierReportList extends StatelessWidget {
  const CashierReportList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cashiers = [];

    return Column(
      children: cashiers.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surface : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item[0].toString()[0],
                      style: TextStyle(
                        color: isDark ? colorScheme.primary : const Color(0xFF334155),
                        fontWeight: FontWeight.w800,
                      ),
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
                      ],
                    ),
                  ),
                  Text(
                    item[2],
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _MiniValue(label: 'Sales', value: item[2]),
                  ),
                  Expanded(
                    child: _MiniValue(label: 'Credit', value: item[3]),
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

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
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
