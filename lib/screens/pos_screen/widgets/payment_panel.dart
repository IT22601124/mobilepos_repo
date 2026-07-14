import 'package:flutter/material.dart';


class PaymentPanel extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<String> onPaymentChanged;
  final VoidCallback onHold;
  final VoidCallback onPay;

  const PaymentPanel({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.onDiscountChanged,
    required this.onPaymentChanged,
    required this.onHold,
    required this.onPay,
  });

  String money(double value) => 'LKR ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'Subtotal', value: money(subtotal)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      prefixIcon: const Icon(Icons.discount_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      onDiscountChanged(double.tryParse(value) ?? 0);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: const ['Cash', 'Card', 'Credit', 'Wallet']
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onPaymentChanged(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Discount', value: money(discount)),
            const SizedBox(height: 4),
            _SummaryRow(label: 'Tax 8%', value: money(tax)),
            _SummaryRow(label: 'Total', value: money(total), strong: true),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onHold,
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Hold'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.receipt_long),
                    label: Text('Pay ${money(total)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23C16B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: strong ? const Color(0xFF23C16B) : const Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
