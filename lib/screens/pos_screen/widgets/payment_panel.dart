import 'package:flutter/material.dart';

class PaymentPanel extends StatefulWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final bool isCartEmpty;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<String> onPaymentChanged;
  final VoidCallback onHold;
  final VoidCallback onPay;

  const PaymentPanel({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.isCartEmpty,
    required this.onDiscountChanged,
    required this.onPaymentChanged,
    required this.onHold,
    required this.onPay,
  });

  @override
  State<PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends State<PaymentPanel> {
  bool _isExpanded = false;

  String money(double value) => 'LKR ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.isCartEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colors.surface,
          border: Border(top: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
        ),
        child: SafeArea(
          top: false,
          child: Text(
            'Select items to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colors.surface,
        border: isDark ? Border(top: BorderSide(color: colors.outline.withValues(alpha: 0.1))) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Professional Expandable Header
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PAYABLE',
                                style: TextStyle(
                                  color: colors.onSurface.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                money(widget.total),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                            color: colors.primary,
                          ),
                        ],
                      ),
                      if (_isExpanded) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1),
                        ),
                        _SummaryRow(label: 'Subtotal', value: money(widget.subtotal)),
                        _SummaryRow(label: 'Discount', value: money(widget.discount)),
                        _SummaryRow(label: 'Tax (8%)', value: money(widget.tax)),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Controls Section
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _CompactField(
                          label: 'Discount',
                          icon: Icons.sell_outlined,
                          onChanged: (v) => widget.onDiscountChanged(double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _CompactDropdown(
                          value: widget.paymentMethod,
                          items: const ['Cash', 'Card', 'Credit', 'Wallet'],
                          onChanged: (v) => v != null ? widget.onPaymentChanged(v) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          label: 'HOLD',
                          onPressed: widget.onHold,
                          icon: Icons.pause_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _PrimaryButton(
                          label: 'COMPLETE SALE',
                          onPressed: widget.onPay,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _CompactField({required this.label, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CompactDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: items.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const _PrimaryButton({required this.label, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981), // Modern Emerald Green
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const _SecondaryButton({required this.label, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        side: BorderSide(color: Theme.of(context).dividerColor),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
      ),
    );
  }
}
