import 'package:flutter/material.dart';

class ManagementHeader extends StatelessWidget {
  const ManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      color: colorScheme.surface,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.storefront,
              color: isDark ? colorScheme.primary : const Color(0xFF334155),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POS Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Reports, stock, cashiers and credit',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: isDark ? const Color(0xFF10B981) : const Color(0xFF16A34A),
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'Live API',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF10B981) : const Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
