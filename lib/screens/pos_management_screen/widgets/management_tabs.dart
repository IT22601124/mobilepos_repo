import 'package:flutter/material.dart';

class ManagementTabs extends StatelessWidget {
  final List<String> tabs;
  final String activeTab;
  final ValueChanged<String> onChanged;

  const ManagementTabs({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 54,
      color: colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final tab = tabs[index];
          final active = tab == activeTab;

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(tab),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active
                    ? (isDark ? colorScheme.primary : const Color(0xFF0F172A))
                    : (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: active
                      ? (isDark ? colorScheme.onPrimary : Colors.white)
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
