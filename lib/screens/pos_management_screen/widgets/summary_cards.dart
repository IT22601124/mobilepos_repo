import 'package:flutter/material.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Bills', '18', Icons.receipt_long, const Color(0xFF23C16B)],
      ['Items', '35', Icons.shopping_bag_outlined, const Color(0xFFE056FD)],
      ['Held', '3', Icons.pause_circle_outline, const Color(0xFFF59E0B)],
      ['Cashiers', '4', Icons.people_outline, const Color(0xFF2F80ED)],
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item[3] as Color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item[2] as IconData, color: Colors.white),
              const Spacer(),
              Text(
                item[0] as String,
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                item[1] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}