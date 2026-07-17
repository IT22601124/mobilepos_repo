import 'package:flutter/material.dart';

class CashierReportList extends StatelessWidget {
  const CashierReportList({super.key});

  @override
  Widget build(BuildContext context) {
    final cashiers = [];

    return Column(
      children: cashiers.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF23C16B),
                    child: Text(item[0].toString()[0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item[0], style: const TextStyle(fontWeight: FontWeight.w900)),
                        Text(item[1], style: const TextStyle(color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Text(item[2], style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(child: _MiniValue(label: 'Sales', value: item[2])),
                  Expanded(child: _MiniValue(label: 'Credit', value: item[3])),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
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