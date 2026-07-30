import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final double cartQty;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.cartQty = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final totalStock = (product['stock'] as num?)?.toDouble() ?? 0;
    final availableStock = totalStock - cartQty;
    final isWeighted = product['is_weighted'] == true;
    final unitName = product['unit_name']?.toString() ?? (isWeighted ? 'kg' : 'pcs');
    
    final lowStock = availableStock <= (isWeighted ? 2.0 : 5.0);
    final outOfStock = availableStock <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: colorScheme.outline.withValues(alpha: 0.1)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: outOfStock
                        ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEE2E2))
                        : lowStock
                            ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7))
                            : (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    outOfStock
                        ? Icons.not_interested_rounded
                        : isWeighted
                            ? Icons.scale_outlined
                            : lowStock
                                ? Icons.warning_amber_rounded
                                : Icons.inventory_2_outlined,
                    color: outOfStock
                        ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFB91C1C))
                        : lowStock
                            ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                            : (isDark ? colorScheme.primary : const Color(0xFF475569)),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${product['sku']}  •  ${product['category']}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LKR ${product['price'].toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: outOfStock
                            ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEE2E2))
                            : lowStock
                                ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7))
                                : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        outOfStock
                            ? 'Out of Stock'
                            : lowStock
                                ? 'Low Stock: ${isWeighted ? availableStock.toStringAsFixed(3) : availableStock.toInt()} $unitName'
                                : 'Stock: ${isWeighted ? availableStock.toStringAsFixed(3) : availableStock.toInt()} $unitName',
                        style: TextStyle(
                          color: outOfStock
                              ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFB91C1C))
                              : lowStock
                                  ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))
                                  : (isDark ? const Color(0xFF10B981) : const Color(0xFF166534)),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
