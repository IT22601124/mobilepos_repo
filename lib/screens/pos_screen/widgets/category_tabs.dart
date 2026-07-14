import 'package:flutter/material.dart';


class CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const CategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = categories[index];
          final active = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: active,
            selectedColor: const Color(0xFF23C16B),
            labelStyle: TextStyle(
              color: active ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => onChanged(category),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}