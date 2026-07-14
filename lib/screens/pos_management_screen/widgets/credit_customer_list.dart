import 'package:flutter/material.dart';

class CreditCustomerList extends StatelessWidget {
  const CreditCustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    final customers = [
      ['Tharindu Stores', '0787450363', 'LKR 50,000', 'LKR 12,500'],
      ['Colombo Mini Mart', '0771122334', 'LKR 35,000', 'LKR 8,000'],
      ['Kandy Wholesale', '0714455667', 'LKR 75,000', 'LKR 72,000'],
    ];

    return Column(
      children: customers.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF7ED),
                child: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item[0], style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(item[1], style: const TextStyle(color: Color(0xFF6B7280))),
                    const SizedBox(height: 6),
                    Text('Limit ${item[2]}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Balance', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  Text(
                    item[3],
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w900,
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
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE5E7EB)),
  );
}