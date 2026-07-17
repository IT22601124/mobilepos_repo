import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final lowStock = stock <= 5;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: lowStock
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: lowStock
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF2F80ED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product['sku']}  |  ${product['category']}',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: lowStock
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      lowStock ? 'Low stock: $stock' : 'Stock $stock',
                      style: TextStyle(
                        color: lowStock
                            ? const Color(0xFFB45309)
                            : const Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.add_circle, color: Color(0xFF23C16B)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Theme.of(context).dividerColor),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );
}
