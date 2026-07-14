import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';
import 'package:mpos/screens/pos_screen/widgets/card_tems.dart';
import 'package:mpos/screens/pos_screen/widgets/category_tabs.dart';
import 'package:mpos/screens/pos_screen/widgets/payment_panel.dart';
import 'package:mpos/screens/pos_screen/widgets/product_card.dart';
import 'package:mpos/screens/pos_screen/widgets/searchbox.dart';

class PosTerminalScreen extends StatefulWidget {
  const PosTerminalScreen({super.key});

  @override
  State<PosTerminalScreen> createState() => _PosTerminalScreenState();
}

class _PosTerminalScreenState extends State<PosTerminalScreen> {
  final _dio = DioClient().dio;

  final List<Map<String, dynamic>> _fallbackProducts = [
    {
      'id': 1,
      'name': 'Milk 1L',
      'sku': 'DRY-001',
      'price': 420.0,
      'stock': 18,
      'category': 'Dairy',
    },
    {
      'id': 2,
      'name': 'Basmati Rice 5kg',
      'sku': 'GRY-101',
      'price': 3450.0,
      'stock': 22,
      'category': 'Grocery',
    },
    {
      'id': 3,
      'name': 'Coconut Oil 1L',
      'sku': 'GRY-102',
      'price': 910.0,
      'stock': 16,
      'category': 'Grocery',
    },
    {
      'id': 4,
      'name': 'Orange Juice',
      'sku': 'BEV-031',
      'price': 520.0,
      'stock': 20,
      'category': 'Beverage',
    },
  ];

  late List<Map<String, dynamic>> products = List.of(_fallbackProducts);
  final List<Map<String, dynamic>> cart = [];

  String selectedCategory = 'All';
  String paymentMethod = 'Cash';
  String query = '';
  double discount = 0;
  bool isLoading = true;
  String? error;

  List<String> categories = ['All', 'Dairy', 'Grocery', 'Beverage'];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  double get subtotal {
    return cart.fold(
      0,
      (sum, item) => sum + ((item['price'] as num) * (item['qty'] as num)),
    );
  }

  double get discountAmount => discount.clamp(0, subtotal).toDouble();

  double get tax {
    return (subtotal - discountAmount) * 0.08;
  }

  double get total {
    return subtotal - discountAmount + tax;
  }

  void addToCart(Map<String, dynamic> product) {
    final index = cart.indexWhere((item) => item['sku'] == product['sku']);

    setState(() {
      if (index >= 0) {
        cart[index]['qty'] += 1;
      } else {
        cart.add({...product, 'qty': 1});
      }
    });
  }

  void updateQty(int index, int qty) {
    setState(() {
      if (qty <= 0) {
        cart.removeAt(index);
      } else {
        cart[index]['qty'] = qty;
      }
    });
  }

  List<Map<String, dynamic>> get filteredProducts {
    Iterable<Map<String, dynamic>> result = products;

    if (selectedCategory != 'All') {
      result = result.where((item) => item['category'] == selectedCategory);
    }

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      result = result.where((item) {
        final name = item['name'].toString().toLowerCase();
        final sku = item['sku'].toString().toLowerCase();
        return name.contains(normalizedQuery) || sku.contains(normalizedQuery);
      });
    }

    return result.toList();
  }

  String money(double value) {
    return 'LKR ${value.toStringAsFixed(0)}';
  }

  Future<void> _loadCatalog() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final responses = await Future.wait([
        _dio.get(ApiRoutes.products),
        _dio.get(ApiRoutes.categories),
      ]);

      final productRows = _extractRows(responses[0].data);
      final categoryRows = _extractRows(responses[1].data);
      final loadedProducts = productRows.map(_productFromApi).toList();
      final loadedCategories = categoryRows
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        products = loadedProducts.isEmpty
            ? List.of(_fallbackProducts)
            : loadedProducts;
        categories = ['All', ...loadedCategories];
        if (!categories.contains(selectedCategory)) selectedCategory = 'All';
      });
    } catch (apiError) {
      setState(() {
        products = List.of(_fallbackProducts);
        categories = ['All', 'Dairy', 'Grocery', 'Beverage'];
        error = 'Using sample catalog. ${apiError.toString()}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    const keys = [
      'products',
      'categories',
      'pos_sales',
      'sales',
      'data',
      'rows',
      'items',
      'records',
    ];
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (payload is Map) {
      for (final key in keys) {
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

  Map<String, dynamic> _productFromApi(Map<String, dynamic> item) {
    final category = item['category'];
    return {
      'id': item['id'],
      'name': item['name']?.toString() ?? 'Unnamed product',
      'sku':
          (item['product_code'] ?? item['sku'] ?? item['barcode'] ?? item['id'])
              .toString(),
      'price': _toDouble(item['selling_price'] ?? item['price']),
      'stock': _toDouble(item['stock_quantity'] ?? item['stock']).toInt(),
      'category': category is Map
          ? category['name']?.toString() ?? 'Uncategorized'
          : item['category_name']?.toString() ?? 'Uncategorized',
      'tax_rate': _toDouble(item['tax_rate']),
      'discount_rate': _toDouble(item['discount_rate']),
    };
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void completeSale() {
    if (cart.isEmpty) return;
    context.go(
      '/pos_payment',
      extra: {
        'subtotal': subtotal,
        'discount': discountAmount,
        'tax': tax,
        'total': total,
        'paymentMethod': paymentMethod,
        'cart': List<Map<String, dynamic>>.from(cart),
      },
    );
  }

  Future<void> holdOrder() async {
    if (cart.isEmpty) return;

    try {
      await _dio.post(ApiRoutes.posSales, data: _salePayload('held'));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order held successfully')));

      setState(() {
        cart.clear();
        discount = 0;
      });
    } catch (apiError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not hold order. ${apiError.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Map<String, dynamic> _salePayload(String status) {
    return {
      'subtotal': subtotal,
      'discount_total': discountAmount,
      'tax_total': tax,
      'grand_total': total,
      'paid_amount': 0,
      'balance_amount': total,
      'status': status,
      'notes': 'Held from mobile POS',
      'items': cart.map(_saleItemPayload).toList(),
      'payments': const [],
    };
  }

  Map<String, dynamic> _saleItemPayload(Map<String, dynamic> item) {
    final qty = _toDouble(item['qty']);
    final unitPrice = _toDouble(item['price']);
    final gross = qty * unitPrice;
    final itemDiscount = subtotal <= 0
        ? 0
        : discountAmount * (gross / subtotal);
    final taxable = gross - itemDiscount;
    final taxRate = _toDouble(item['tax_rate']);
    final itemTax = taxRate > 0
        ? taxable * (taxRate / 100)
        : tax * (gross / subtotal);

    return {
      'product_id': item['id'],
      'qty': qty,
      'unit_price': unitPrice,
      'discount': itemDiscount,
      'tax': itemTax,
      'line_total': taxable + itemTax,
    };
  }

  Future<void> showHeldOrders() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _HeldOrdersSheet(
        loadOrders: _loadHeldOrders,
        deleteOrder: _deleteHeldOrder,
        onResume: _resumeHeldOrder,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadHeldOrders() async {
    final response = await _dio.get(
      ApiRoutes.posSales,
      queryParameters: {'status': 'held'},
    );
    return _extractRows(response.data);
  }

  Future<String> _deleteHeldOrder(dynamic saleId) async {
    final response = await _dio.delete('${ApiRoutes.posSales}/$saleId');
    final data = response.data;
    if (data is Map && data['success'] == true) {
      return data['message']?.toString() ?? 'Held order removed';
    }
    throw Exception('Failed to remove held order');
  }

  void _resumeHeldOrder(Map<String, dynamic> sale) {
    final items = (sale['items'] as List?) ?? const [];
    final restoredCart = items
        .whereType<Map>()
        .map((item) => _cartItemFromHeldSale(Map<String, dynamic>.from(item)))
        .whereType<Map<String, dynamic>>()
        .toList();

    if (restoredCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Held order has no items to resume.')),
      );
      return;
    }

    setState(() {
      cart
        ..clear()
        ..addAll(restoredCart);
      discount = _toDouble(sale['discount_total']);
      paymentMethod = 'Cash';
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resumed ${sale['sale_no'] ?? 'held order'}')),
    );
  }

  Map<String, dynamic>? _cartItemFromHeldSale(Map<String, dynamic> item) {
    final product = item['product'];
    final productMap = product is Map
        ? Map<String, dynamic>.from(product)
        : null;
    final productId = item['product_id'] ?? productMap?['id'];
    final existingProduct = products.cast<Map<String, dynamic>?>().firstWhere(
      (product) => product?['id']?.toString() == productId?.toString(),
      orElse: () => null,
    );

    final source = existingProduct ?? _productFromHeldItem(item, productMap);
    if (source == null) return null;

    return {...source, 'qty': _toDouble(item['qty']).toInt().clamp(1, 999999)};
  }

  Map<String, dynamic>? _productFromHeldItem(
    Map<String, dynamic> item,
    Map<String, dynamic>? product,
  ) {
    final productId = item['product_id'] ?? product?['id'];
    if (productId == null) return null;

    final category = product?['category'];
    return {
      'id': productId,
      'name': product?['name']?.toString() ?? 'Product $productId',
      'sku':
          (product?['product_code'] ??
                  product?['sku'] ??
                  product?['barcode'] ??
                  productId)
              .toString(),
      'price': _toDouble(item['unit_price'] ?? product?['selling_price']),
      'stock': _toDouble(product?['stock_quantity']).toInt(),
      'category': category is Map
          ? category['name']?.toString() ?? 'Uncategorized'
          : 'Uncategorized',
      'tax_rate': _toDouble(product?['tax_rate']),
      'discount_rate': _toDouble(product?['discount_rate']),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 30),
              SearchBox(
                onChanged: (value) {
                  setState(() {
                    query = value;
                  });
                },
              ),
              CategoryTabs(
                categories: categories,
                selectedCategory: selectedCategory,
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    if (error != null)
                      _CatalogNotice(message: error!, onRetry: _loadCatalog),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: showHeldOrders,
                        icon: const Icon(Icons.pause_circle_outline),
                        label: const Text('Held Orders'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...filteredProducts.map(
                      (product) => ProductCard(
                        product: product,
                        onTap: () => addToCart(product),
                      ),
                    ),
                    if (filteredProducts.isEmpty) const _NoProductsFound(),
                    const SizedBox(height: 12),
                    const Text(
                      'Cart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (cart.isEmpty)
                      const _EmptyCart()
                    else
                      ...cart.asMap().entries.map(
                        (entry) => CartItem(
                          item: entry.value,
                          onMinus: () =>
                              updateQty(entry.key, entry.value['qty'] - 1),
                          onPlus: () =>
                              updateQty(entry.key, entry.value['qty'] + 1),
                          onRemove: () => updateQty(entry.key, 0),
                        ),
                      ),
                  ],
                ),
              ),
              PaymentPanel(
                subtotal: subtotal,
                discount: discount,
                tax: tax,
                total: total,
                paymentMethod: paymentMethod,
                onDiscountChanged: (value) {
                  setState(() {
                    discount = value.clamp(0, subtotal).toDouble();
                  });
                },
                onPaymentChanged: (value) {
                  setState(() {
                    paymentMethod = value;
                  });
                },
                onHold: holdOrder,
                onPay: completeSale,
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 70,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'pos_home_fab',
                backgroundColor: const Color(0xFF23C16B),
                onPressed: () => context.go('/mainNavigation'),
                child: const Icon(Icons.home, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          'No items added',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

class _NoProductsFound extends StatelessWidget {
  const _NoProductsFound();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          'No products found',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

class _CatalogNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CatalogNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _HeldOrdersSheet extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() loadOrders;
  final Future<String> Function(dynamic saleId) deleteOrder;
  final ValueChanged<Map<String, dynamic>> onResume;

  const _HeldOrdersSheet({
    required this.loadOrders,
    required this.deleteOrder,
    required this.onResume,
  });

  @override
  State<_HeldOrdersSheet> createState() => _HeldOrdersSheetState();
}

class _HeldOrdersSheetState extends State<_HeldOrdersSheet> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _heldOrders = [];
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await widget.loadOrders();
      if (!mounted) return;
      setState(() => _heldOrders = orders);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeHeldOrder(Map<String, dynamic> order) async {
    final saleId = order['id'];
    if (saleId == null) {
      _showSnack('Held order id missing', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove held order'),
        content: const Text('Remove this held order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final idText = saleId.toString();
    setState(() => _deletingIds.add(idText));

    try {
      final message = await widget.deleteOrder(saleId);
      if (!mounted) return;
      setState(() {
        _heldOrders.removeWhere((item) => item['id']?.toString() == idText);
      });
      _showSnack(message);
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(idText));
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF23C16B),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        return data['error']?.toString() ??
            data['message']?.toString() ??
            'Failed to remove held order';
      }
      return error.message ?? 'Failed to remove held order';
    }
    final text = error.toString();
    if (text.contains('error:')) return text.split('error:').last.trim();
    if (text.contains('message:')) return text.split('message:').last.trim();
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Held Orders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadOrders,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _HeldOrderNotice(message: _error!, onRetry: _loadOrders)
            else if (_heldOrders.isEmpty)
              const _HeldOrderEmpty()
            else
              ..._heldOrders.map((order) {
                final idText = order['id']?.toString() ?? '';
                return _HeldOrderCard(
                  order: order,
                  isDeleting: _deletingIds.contains(idText),
                  onResume: () => widget.onResume(order),
                  onRemove: () => _removeHeldOrder(order),
                );
              }),
          ],
        );
      },
    );
  }
}

class _HeldOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDeleting;
  final VoidCallback onResume;
  final VoidCallback onRemove;

  const _HeldOrderCard({
    required this.order,
    required this.isDeleting,
    required this.onResume,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? const [];
    final total = _money(_toDoubleStatic(order['grand_total']));
    final soldAt =
        order['sold_at']?.toString() ?? order['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(
                  Icons.pause_circle_outline,
                  color: Color(0xFF2F80ED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['sale_no']?.toString() ?? 'Held order',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${items.length} item${items.length == 1 ? '' : 's'} / $soldAt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                total,
                style: const TextStyle(
                  color: Color(0xFF23C16B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDeleting ? null : onResume,
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Resume Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23C16B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove held order',
                onPressed: isDeleting ? null : onRemove,
                icon: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeldOrderNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HeldOrderNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _HeldOrderEmpty extends StatelessWidget {
  const _HeldOrderEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Center(
        child: Text(
          'No held orders found',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

String _money(double value) => 'LKR ${value.toStringAsFixed(0)}';

double _toDoubleStatic(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    boxShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}
