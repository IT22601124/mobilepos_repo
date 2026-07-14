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
      height: 56,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final tab = tabs[index];
          final active = tab == activeTab;

          return ChoiceChip(
            label: Text(tab),
            selected: active,
            selectedColor: const Color(0xFF23C16B),
            backgroundColor: const Color(0xFFF3F4F6),
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