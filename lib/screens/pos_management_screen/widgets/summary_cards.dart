import 'package:flutter/material.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Bills', '0', Icons.receipt_long, const Color(0xFF2563EB)],
      ['Items', '0', Icons.shopping_bag_outlined, const Color(0xFF475569)],
      ['Held', '0', Icons.pause_circle_outline, const Color(0xFFD97706)],
      ['Cashiers', '0', Icons.people_outline, const Color(0xFF059669)],
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: items.map((item) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFEAF1FB),
            borderRadius: BorderRadius.circular(8),
            border: isDark ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item[2] as IconData, color: item[3] as Color),
              const Spacer(),
              Text(
                item[0] as String,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              Text(
                item[1] as String,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
