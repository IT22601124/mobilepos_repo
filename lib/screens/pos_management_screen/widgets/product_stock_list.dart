import 'package:flutter/material.dart';

class ProductStockList extends StatelessWidget {
  const ProductStockList({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [];

    return Column(
      children: products.map((item) {
        final low = item[3] == 'Low stock';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF334155),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item[0].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      item[1].toString(),
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item[2]} stock',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    item[3].toString(),
                    style: TextStyle(
                      color: low
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF23C16B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: const Color(0xFFEAF1FB),
    borderRadius: BorderRadius.circular(6),
  );
}
