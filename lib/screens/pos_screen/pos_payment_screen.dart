import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';
import 'package:mpos/utils/app_back_scope.dart';

class PosPaymentScreen extends StatefulWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final List<Map<String, dynamic>> cart;

  const PosPaymentScreen({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.cart,
  });

  @override
  State<PosPaymentScreen> createState() => _PosPaymentScreenState();
}

class _PosPaymentScreenState extends State<PosPaymentScreen> {
  final _dio = DioClient().dio;
  late String paymentMethod;
  double amountPaid = 0;
  String selectedCustomer = 'Walk-in customer';
  int dueDays = 14;
  bool isLoadingCustomers = true;
  bool isSubmitting = false;

  final List<Map<String, dynamic>> creditCustomers = [
    {
      'name': 'Walk-in customer',
      'id': null,
      'phone': '-',
      'creditLimit': 0.0,
      'balance': 0.0,
      'status': false,
    },
    {
      'name': 'Tharindu Stores',
      'id': 1,
      'phone': '0787450363',
      'creditLimit': 50000.0,
      'balance': 12500.0,
      'status': true,
    },
    {
      'name': 'Colombo Mini Mart',
      'id': 2,
      'phone': '0771122334',
      'creditLimit': 35000.0,
      'balance': 8000.0,
      'status': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    paymentMethod = widget.paymentMethod;
    if (paymentMethod != 'Cash' && paymentMethod != 'Credit') {
      amountPaid = widget.total;
    }
    _loadCustomers();
  }

  String money(double value) => 'LKR ${value.toStringAsFixed(0)}';

  double get changeDue {
    if (paymentMethod != 'Cash') return 0;
    return amountPaid > widget.total ? amountPaid - widget.total : 0;
  }

  double get balanceDue {
    return amountPaid < widget.total ? widget.total - amountPaid : 0;
  }

  double get creditAmount {
    if (paymentMethod != 'Credit') return 0;
    return widget.total - amountPaid;
  }

  Map<String, dynamic> get customer {
    return creditCustomers.firstWhere(
      (item) => item['name'] == selectedCustomer,
      orElse: () => creditCustomers.first,
    );
  }

  double get availableCredit {
    return (customer['creditLimit'] as double) -
        (customer['balance'] as double);
  }

  bool get canComplete {
    if (widget.cart.isEmpty || widget.total <= 0) return false;

    if (paymentMethod == 'Cash') {
      return amountPaid >= widget.total;
    }

    if (paymentMethod == 'Credit') {
      return customer['status'] == true &&
          selectedCustomer != 'Walk-in customer' &&
          creditAmount > 0 &&
          availableCredit >= creditAmount;
    }

    return true;
  }

  void addAmount(String value) {
    setState(() {
      if (value == 'C') {
        amountPaid = 0;
        return;
      }

      final current = amountPaid.toStringAsFixed(0);
      final next = current == '0' ? value : current + value;
      amountPaid = double.tryParse(next) ?? amountPaid;
    });
  }

  void removeAmount() {
    setState(() {
      final current = amountPaid.toStringAsFixed(0);
      if (current.length <= 1) {
        amountPaid = 0;
      } else {
        amountPaid =
            double.tryParse(current.substring(0, current.length - 1)) ?? 0;
      }
    });
  }

  Future<void> _loadCustomers() async {
    try {
      final response = await _dio.get(ApiRoutes.customers);
      final customers = _extractRows(response.data)
          .map(
            (item) => {
              'id': item['id'],
              'name': item['name']?.toString() ?? 'Customer',
              'phone': item['phone']?.toString() ?? '-',
              'creditLimit': _toDouble(item['credit_limit']),
              'balance': _toDouble(item['current_balance']),
              'status': _asBool(item['status']),
            },
          )
          .where((item) => item['name'] != 'Customer')
          .toList();

      if (customers.isNotEmpty) {
        setState(() {
          creditCustomers
            ..clear()
            ..add({
              'name': 'Walk-in customer',
              'id': null,
              'phone': '-',
              'creditLimit': 0.0,
              'balance': 0.0,
              'status': false,
            })
            ..addAll(customers);
          if (!creditCustomers.any(
            (item) => item['name'] == selectedCustomer,
          )) {
            selectedCustomer = 'Walk-in customer';
          }
        });
      }
    } catch (_) {
      // Keep fallback customers so the payment screen remains usable offline.
    } finally {
      if (mounted) setState(() => isLoadingCustomers = false);
    }
  }

  Future<void> completePayment() async {
    if (!canComplete || isSubmitting) return;
    setState(() => isSubmitting = true);

    try {
      final payload = _salePayload();
      final response = await _dio.post(ApiRoutes.posSales, data: payload);
      final data = _asMap(response.data);
      final sale = _asMap(data['pos_sale']);
      final saleNo =
          sale['sale_no']?.toString() ??
          payload['sale_no']?.toString() ??
          'POS-${DateTime.now().millisecondsSinceEpoch}';
      final storeProfile = await _loadStoreProfileForReceipt();

      if (!mounted) return;
      context.go(
        '/pos-payment-success',
        extra: {
          'saleNo': saleNo,
          'paymentMethod': paymentMethod,
          'subtotal': widget.subtotal,
          'discount': widget.discount,
          'tax': widget.tax,
          'total': widget.total,
          'paid': amountPaid,
          'change': changeDue,
          'creditAmount': creditAmount,
          'customerName': paymentMethod == 'Credit'
              ? selectedCustomer
              : 'Walk-in customer',
          'cart': widget.cart,
          'storeProfile': storeProfile,
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageFor(error)),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Map<String, dynamic> _salePayload() {
    final backendMethod = _backendPaymentMethod(paymentMethod);
    final items = widget.cart.map(_saleItemPayload).toList();
    final payments = <Map<String, dynamic>>[];

    if (paymentMethod == 'Credit') {
      if (amountPaid > 0) {
        payments.add({'method': 'cash', 'amount': amountPaid});
      }
      payments.add({'method': 'credit', 'amount': creditAmount});
    } else {
      payments.add({
        'method': backendMethod,
        'amount': paymentMethod == 'Cash' ? widget.total : amountPaid,
      });
    }

    return {
      'customer_id': paymentMethod == 'Credit' ? customer['id'] : null,
      'subtotal': widget.subtotal,
      'discount_total': widget.discount,
      'tax_total': widget.tax,
      'grand_total': widget.total,
      'paid_amount': amountPaid,
      'balance_amount': paymentMethod == 'Credit' ? creditAmount : 0,
      'status': 'completed',
      'notes': paymentMethod == 'Credit' ? 'Due in $dueDays days' : null,
      'items': items,
      'payments': payments,
    };
  }

  Map<String, dynamic> _saleItemPayload(Map<String, dynamic> item) {
    final qty = _toDouble(item['qty']);
    final unitPrice = _toDouble(item['price']);
    final gross = qty * unitPrice;
    final itemDiscount = widget.subtotal <= 0
        ? 0
        : widget.discount * (gross / widget.subtotal);
    final taxable = gross - itemDiscount;
    final taxRate = _toDouble(item['tax_rate']);
    final itemTax = taxRate > 0
        ? taxable * (taxRate / 100)
        : widget.tax * (gross / widget.subtotal);

    return {
      'product_id': item['id'],
      'qty': qty,
      'unit_price': unitPrice,
      'discount': itemDiscount,
      'tax': itemTax,
      'line_total': taxable + itemTax,
    };
  }

  String _backendPaymentMethod(String method) {
    switch (method) {
      case 'Card':
        return 'card';
      case 'Credit':
        return 'credit';
      case 'Wallet':
        return 'mobile';
      default:
        return 'cash';
    }
  }

  Future<Map<String, dynamic>> _loadStoreProfileForReceipt() async {
    try {
      final response = await _dio.get(ApiRoutes.storeProfile);
      final data = _asMap(response.data);
      return _extractStoreProfile(data);
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _extractStoreProfile(Map<String, dynamic> payload) {
    for (final key in ['store_profile', 'storeProfile', 'profile', 'data']) {
      final value = _asMap(payload[key]);
      if (value.isNotEmpty) return value;
    }
    if (payload.containsKey('store_name') ||
        payload.containsKey('legal_name')) {
      return payload;
    }
    return {};
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (payload is Map) {
      for (final key in ['customers', 'data', 'rows', 'items', 'records']) {
        final value = payload[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }
    return [];
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {};
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    return [
      'true',
      '1',
      'active',
      'yes',
    ].contains(value?.toString().toLowerCase());
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _messageFor(Object error) {
    final text = error.toString();
    if (text.contains('401')) {
      return 'Please login again before completing sale.';
    }
    if (text.contains('SocketException') || text.contains('connection')) {
      return 'Could not reach backend. Sale was not saved.';
    }
    return text;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pos_terminal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = paymentMethod == 'Credit';

    return AppBackScope(
      fallbackRoute: '/pos_terminal',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text(
            'Complete Payment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    _TotalCard(total: widget.total),
                    const SizedBox(height: 14),

                    _PaymentMethods(
                      selected: paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          paymentMethod = value;

                          if (value == 'Cash' || value == 'Credit') {
                            amountPaid = 0;
                          } else {
                            amountPaid = widget.total;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    if (isCredit) ...[
                      _CreditBox(
                        customers: creditCustomers,
                        selectedCustomer: selectedCustomer,
                        dueDays: dueDays,
                        availableCredit: availableCredit,
                        creditAmount: creditAmount,
                        isLoading: isLoadingCustomers,
                        onCustomerChanged: (value) {
                          setState(() {
                            selectedCustomer = value;
                          });
                        },
                        onDueDaysChanged: (value) {
                          setState(() {
                            dueDays = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    _AmountBox(
                      paymentMethod: paymentMethod,
                      amountPaid: amountPaid,
                      total: widget.total,
                      balanceDue: balanceDue,
                      changeDue: changeDue,
                      creditAmount: creditAmount,
                      onAmountChanged: (value) {
                        setState(() {
                          amountPaid = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),
                    _OrderSummary(
                      subtotal: widget.subtotal,
                      discount: widget.discount,
                      tax: widget.tax,
                      total: widget.total,
                      cart: widget.cart,
                    ),

                    if (!canComplete)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          paymentMethod == 'Cash'
                              ? 'Enter enough cash to complete payment.'
                              : paymentMethod == 'Credit'
                              ? 'Select active customer and valid credit amount.'
                              : widget.cart.isEmpty
                              ? 'Add at least one item to complete payment.'
                              : '',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              _Keypad(
                onTap: addAmount,
                onBackspace: removeAmount,
                onComplete: completePayment,
                canComplete: canComplete && !isSubmitting,
                buttonText: isCredit
                    ? 'Complete Credit ${money(creditAmount)}'
                    : 'Complete ${money(widget.total)}',
                isSubmitting: isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;

  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount to Pay',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            'LKR ${total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF23C16B),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PaymentMethods({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['Cash', 'Card', 'Credit', 'Wallet'].map((method) {
        final active = selected == method;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: OutlinedButton(
              onPressed: () => onChanged(method),
              style: OutlinedButton.styleFrom(
                backgroundColor: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).cardColor,
                foregroundColor: active
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(method),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AmountBox extends StatelessWidget {
  final String paymentMethod;
  final double amountPaid;
  final double total;
  final double balanceDue;
  final double changeDue;
  final double creditAmount;
  final ValueChanged<double> onAmountChanged;

  const _AmountBox({
    required this.paymentMethod,
    required this.amountPaid,
    required this.total,
    required this.balanceDue,
    required this.changeDue,
    required this.creditAmount,
    required this.onAmountChanged,
  });

  String money(double value) => 'LKR ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: paymentMethod == 'Credit' ? 'Paid now' : 'Amount paid',
              prefixIcon: const Icon(Icons.payments_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            controller: TextEditingController(
              text: amountPaid == 0 ? '' : amountPaid.toStringAsFixed(0),
            ),
            onChanged: (value) {
              onAmountChanged(double.tryParse(value) ?? 0);
            },
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Paid', value: money(amountPaid)),
          if (paymentMethod == 'Cash')
            _InfoRow(label: 'Balance', value: money(balanceDue)),
          if (paymentMethod == 'Cash')
            _InfoRow(label: 'Change', value: money(changeDue)),
          if (paymentMethod == 'Credit')
            _InfoRow(label: 'Credit Amount', value: money(creditAmount)),
        ],
      ),
    );
  }
}

class _CreditBox extends StatelessWidget {
  final List<Map<String, dynamic>> customers;
  final String selectedCustomer;
  final int dueDays;
  final double availableCredit;
  final double creditAmount;
  final bool isLoading;
  final ValueChanged<String> onCustomerChanged;
  final ValueChanged<int> onDueDaysChanged;

  const _CreditBox({
    required this.customers,
    required this.selectedCustomer,
    required this.dueDays,
    required this.availableCredit,
    required this.creditAmount,
    required this.isLoading,
    required this.onCustomerChanged,
    required this.onDueDaysChanged,
  });

  String money(double value) => 'LKR ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(),
            ),
          DropdownButtonFormField<String>(
            initialValue: selectedCustomer,
            decoration: InputDecoration(
              labelText: 'Credit customer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: customers.map((customer) {
              return DropdownMenuItem<String>(
                value: customer['name'].toString(),
                child: Text('${customer['name']} - ${customer['phone']}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onCustomerChanged(value);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Due days',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            controller: TextEditingController(text: dueDays.toString()),
            onChanged: (value) {
              onDueDaysChanged(int.tryParse(value) ?? 1);
            },
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Available credit', value: money(availableCredit)),
          _InfoRow(label: 'This sale credit', value: money(creditAmount)),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final List<Map<String, dynamic>> cart;

  const _OrderSummary({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.cart,
  });

  String money(double value) => 'LKR ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...cart.map(
            (item) => _InfoRow(
              label: '${item['name']} x ${item['qty']}',
              value: money((item['price'] as double) * (item['qty'] as int)),
            ),
          ),
          const Divider(),
          _InfoRow(label: 'Subtotal', value: money(subtotal)),
          _InfoRow(label: 'Discount', value: money(discount)),
          _InfoRow(label: 'Tax 8%', value: money(tax)),
          _InfoRow(label: 'Total', value: money(total), strong: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _InfoRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).hintColor,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong
                  ? const Color(0xFF23C16B)
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onTap;
  final VoidCallback onBackspace;
  final VoidCallback onComplete;
  final bool canComplete;
  final String buttonText;
  final bool isSubmitting;

  const _Keypad({
    required this.onTap,
    required this.onBackspace,
    required this.onComplete,
    required this.canComplete,
    required this.buttonText,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final keys = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '0', '00', 'C'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
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
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              childAspectRatio: 2.4,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                ...keys.map(
                  (key) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => onTap(key),
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onBackspace,
                  child: const Icon(Icons.backspace_outlined),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: canComplete ? onComplete : null,
                  child: const Text('Pay'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canComplete ? onComplete : null,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23C16B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
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
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Theme.of(context).dividerColor),
    boxShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}
