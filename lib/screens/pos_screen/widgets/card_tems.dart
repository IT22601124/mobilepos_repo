import 'package:flutter/material.dart';

class CartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  const CartItem({
    super.key,
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lineTotal = item['price'] * item['qty'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: colorScheme.outline.withValues(alpha: 0.1)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'LKR ${item['price'].toStringAsFixed(0)} each',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyBtn(icon: Icons.remove, onTap: onMinus),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item['qty']}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _QtyBtn(icon: Icons.add, onTap: onPlus),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(
                'LKR ${lineTotal.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
