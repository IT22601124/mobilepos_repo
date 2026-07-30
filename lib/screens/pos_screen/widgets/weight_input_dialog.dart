import 'package:flutter/material.dart';

class WeightInputDialog extends StatefulWidget {
  final String productName;
  final String unitName;
  final double currentWeight;
  final double stockAvailable;

  const WeightInputDialog({
    super.key,
    required this.productName,
    required this.unitName,
    this.currentWeight = 0,
    required this.stockAvailable,
  });

  @override
  State<WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<WeightInputDialog> {
  String _value = '';

  @override
  void initState() {
    super.initState();
    if (widget.currentWeight > 0) {
      _value = widget.currentWeight.toString();
    }
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == '.') {
        if (!_value.contains('.')) {
          _value += _value.isEmpty ? '0.' : '.';
        }
      } else {
        _value += key;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_value.isNotEmpty) {
        _value = _value.substring(0, _value.length - 1);
      }
    });
  }

  void _onClear() {
    setState(() {
      _value = '';
    });
  }

  void _submit() {
    final double? weight = double.tryParse(_value);
    if (weight != null && weight > 0) {
      if (weight > widget.stockAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insufficient stock. Max available: ${widget.stockAvailable} ${widget.unitName}')),
        );
        return;
      }
      Navigator.pop(context, weight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.productName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter weight in ${widget.unitName}',
              style: TextStyle(color: theme.hintColor, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _value.isEmpty ? '0.000' : _value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _value.isEmpty ? theme.hintColor.withOpacity(0.5) : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.unitName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                ...['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'].map((key) => _NumpadButton(
                      label: key,
                      onTap: () => _onKeyTap(key),
                    )),
                _NumpadButton(
                  icon: Icons.backspace_outlined,
                  onTap: _onBackspace,
                  color: colorScheme.error.withOpacity(0.1),
                  iconColor: colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onClear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CLEAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.w900)),
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

class _NumpadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _NumpadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: icon != null
              ? Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary)
              : Text(
                  label!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }
}
