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
    return Container(
      height: 58,
      color: Theme.of(context).cardColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final tab = tabs[index];
          final active = tab == activeTab;

          return ChoiceChip(
            label: Text(tab),
            selected: active,
            selectedColor: const Color(0xFF23C16B),
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(
              color: active
                  ? const Color(0xFF23C16B)
                  : Theme.of(context).dividerColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: TextStyle(
              color: active ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => onChanged(tab),
          );
        },
      ),
    );
  }
}
