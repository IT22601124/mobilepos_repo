import 'package:flutter/material.dart';

class CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final category = categories[index];
          final active = category == selectedCategory;

          return InkWell(
            onTap: () => onChanged(category),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}
