import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';
import 'package:mpos/utils/app_back_scope.dart';

import 'widgets/management_header.dart';
import 'widgets/management_option_card.dart';
import 'widgets/management_tabs.dart';

const _statusOptions = [
  _FieldOption('true', 'Active'),
  _FieldOption('false', 'Inactive'),
];

class PosManagementScreen extends StatefulWidget {
  const PosManagementScreen({super.key});

  @override
  State<PosManagementScreen> createState() => _PosManagementScreenState();
}

class _PosManagementScreenState extends State<PosManagementScreen> {
  final Dio _dio = DioClient().dio;
  late final List<_ResourceConfig> _resources;
  String _activeTab = 'Products';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _reportPayload;
  Map<String, Map<String, dynamic>> _settingsPayloads = {};
  final Map<String, List<_LookupOption>> _lookupCache = {};

  static const _green = Color(0xFF23C16B);
  static const _blue = Color(0xFF2F80ED);
  static const _yellow = Color(0xFFF59E0B);
  static const _pink = Color(0xFFE056FD);

  @override
  void initState() {
    super.initState();
    _resources = _buildResources();
    _loadActiveTab();
  }

  List<String> get _tabs => _resources.map((item) => item.tab).toList();

  _ResourceConfig get _activeResource {
    return _resources.firstWhere((item) => item.tab == _activeTab);
  }

  List<_ResourceConfig> _buildResources() {
    return [
      _ResourceConfig(
        tab: 'Products',
        title: 'Product catalog',
        subtitle: 'Manage SKU, barcode, price, stock, tax and status.',
        endpoint: ApiRoutes.products,
        icon: Icons.inventory_2_outlined,
        color: _green,
        fields: const [
          _FieldConfig('name', 'Product name', required: true),
          _FieldConfig('product_code', 'Product code', required: true),
          _FieldConfig('barcode', 'Barcode'),
          _FieldConfig('description', 'Description'),
          _FieldConfig(
            'category_id',
            'Category',
            keyboardType: TextInputType.number,
            lookupEndpoint: ApiRoutes.categories,
          ),
          _FieldConfig(
            'brand_id',
            'Brand',
            keyboardType: TextInputType.number,
            lookupEndpoint: ApiRoutes.brands,
          ),
          _FieldConfig(
            'unit_id',
            'Unit',
            keyboardType: TextInputType.number,
            lookupEndpoint: ApiRoutes.units,
          ),
          _FieldConfig(
            'selling_price',
            'Selling price',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'cost_price',
            'Cost price',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'wholesale_price',
            'Wholesale price',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'stock_quantity',
            'Stock quantity',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'minimum_stock',
            'Minimum stock',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'tax_rate',
            'Tax rate',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'discount_rate',
            'Discount rate',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig('image', 'Image path'),
          _FieldConfig('weight', 'Weight', keyboardType: TextInputType.number),
          _FieldConfig(
            'is_weighted',
            'Weighted item',
            options: [_FieldOption('true', 'Yes'), _FieldOption('false', 'No')],
          ),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {
            'id': 1,
            'name': 'Milk 1L',
            'product_code': 'DRY-001',
            'selling_price': 420,
            'stock_quantity': 18,
            'status': true,
          },
          {
            'id': 2,
            'name': 'Basmati Rice 5kg',
            'product_code': 'GRY-101',
            'selling_price': 3450,
            'stock_quantity': 22,
            'status': true,
          },
        ],
      ),
      _simpleResource(
        'Categories',
        'Product categories',
        'Group products by grocery, dairy, frozen and beverage.',
        ApiRoutes.categories,
        Icons.category_outlined,
        _blue,
      ),
      _simpleResource(
        'Brands',
        'Brands',
        'Manage product brand names and status.',
        ApiRoutes.brands,
        Icons.workspace_premium_outlined,
        _pink,
      ),
      _ResourceConfig(
        tab: 'Units',
        title: 'Units',
        subtitle: 'Configure pcs, kg, litre, pack and box units.',
        endpoint: ApiRoutes.units,
        icon: Icons.straighten,
        color: _blue,
        fields: const [
          _FieldConfig('name', 'Unit name', required: true),
          _FieldConfig('short_name', 'Short name', required: true),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {'id': 1, 'name': 'Pieces', 'short_name': 'pcs', 'status': true},
          {'id': 2, 'name': 'Kilogram', 'short_name': 'kg', 'status': true},
        ],
      ),
      _ResourceConfig(
        tab: 'Suppliers',
        title: 'Suppliers',
        subtitle: 'Supplier contact, phone, email and address.',
        endpoint: ApiRoutes.suppliers,
        icon: Icons.local_shipping_outlined,
        color: _yellow,
        fields: const [
          _FieldConfig('name', 'Supplier name', required: true),
          _FieldConfig('phone', 'Phone', keyboardType: TextInputType.phone),
          _FieldConfig(
            'email',
            'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          _FieldConfig('address', 'Address'),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {
            'id': 1,
            'name': 'Kandy Food Suppliers',
            'phone': '0771122334',
            'status': true,
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Product suppliers',
        title: 'Product supplier links',
        subtitle: 'Connect products with suppliers and supplier prices.',
        endpoint: ApiRoutes.productSuppliers,
        icon: Icons.link,
        color: _green,
        fields: const [
          _FieldConfig(
            'product_id',
            'Product',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.products,
          ),
          _FieldConfig(
            'supplier_id',
            'Supplier',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.suppliers,
          ),
          _FieldConfig(
            'supplier_price',
            'Supplier price',
            keyboardType: TextInputType.number,
          ),
        ],
        sample: [
          {'id': 1, 'product_id': 1, 'supplier_id': 1, 'supplier_price': 360},
        ],
      ),
      _ResourceConfig(
        tab: 'Stock movements',
        title: 'Stock movements',
        subtitle: 'Track purchase, sale, adjustment and returns.',
        endpoint: ApiRoutes.stockMovements,
        icon: Icons.swap_vert,
        color: _blue,
        fields: const [
          _FieldConfig(
            'product_id',
            'Product',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.products,
          ),
          _FieldConfig(
            'type',
            'Movement type',
            options: [
              _FieldOption('purchase', 'Purchase'),
              _FieldOption('sale', 'Sale'),
              _FieldOption('adjustment', 'Adjustment'),
              _FieldOption('return', 'Return'),
            ],
          ),
          _FieldConfig(
            'quantity',
            'Quantity',
            keyboardType: TextInputType.number,
            required: true,
          ),
          _FieldConfig(
            'reference_id',
            'Reference',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig('remarks', 'Remarks'),
        ],
        sample: [
          {
            'id': 1,
            'type': 'purchase',
            'product_id': 2,
            'quantity': 20,
            'created_at': 'Today',
          },
          {
            'id': 2,
            'type': 'sale',
            'product_id': 1,
            'quantity': -2,
            'created_at': 'Today',
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Batches',
        title: 'Product batches',
        subtitle: 'Batch number, purchase price, selling price and expiry.',
        endpoint: ApiRoutes.productBatches,
        icon: Icons.layers_outlined,
        color: _pink,
        fields: const [
          _FieldConfig(
            'product_id',
            'Product',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.products,
          ),
          _FieldConfig('batch_no', 'Batch number', required: true),
          _FieldConfig(
            'purchase_price',
            'Purchase price',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'selling_price',
            'Selling price',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'quantity',
            'Quantity',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig('manufacture_date', 'Manufacture date'),
          _FieldConfig('expiry_date', 'Expiry date'),
        ],
        sample: [
          {
            'id': 1,
            'batch_no': 'BATCH-001',
            'product_id': 1,
            'quantity': 18,
            'expiry_date': '2026-08-20',
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Images',
        title: 'Product images',
        subtitle: 'Attach product image path or upload image.',
        endpoint: ApiRoutes.productImages,
        icon: Icons.image_outlined,
        color: _blue,
        fields: const [
          _FieldConfig(
            'product_id',
            'Product',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.products,
          ),
          _FieldConfig('image_path', 'Image path', required: true),
        ],
        sample: [
          {'id': 1, 'product_id': 1, 'image_path': '/products/milk.png'},
        ],
      ),
      _ResourceConfig(
        tab: 'Taxes',
        title: 'Tax rules',
        subtitle: 'Manage tax name, percentage and status.',
        endpoint: ApiRoutes.taxes,
        icon: Icons.receipt_long,
        color: _yellow,
        fields: const [
          _FieldConfig('name', 'Tax name', required: true),
          _FieldConfig(
            'percentage',
            'Percentage',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {'id': 1, 'name': 'VAT', 'percentage': 8, 'status': true},
        ],
      ),
      _ResourceConfig(
        tab: 'Discounts',
        title: 'Discount rules',
        subtitle: 'Fixed or percentage discount with date range.',
        endpoint: ApiRoutes.discounts,
        icon: Icons.discount_outlined,
        color: _pink,
        fields: const [
          _FieldConfig('name', 'Discount name', required: true),
          _FieldConfig(
            'discount_type',
            'Discount type',
            required: true,
            options: [
              _FieldOption('fixed', 'Fixed amount'),
              _FieldOption('percentage', 'Percentage'),
            ],
          ),
          _FieldConfig('value', 'Value', keyboardType: TextInputType.number),
          _FieldConfig('start_date', 'Start date'),
          _FieldConfig('end_date', 'End date'),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {
            'id': 1,
            'name': 'New Year Discount',
            'discount_type': 'fixed',
            'value': 500,
            'status': true,
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Variants',
        title: 'Product variants',
        subtitle: 'Variant barcode, cost, selling price and stock.',
        endpoint: ApiRoutes.productVariants,
        icon: Icons.alt_route,
        color: _green,
        fields: const [
          _FieldConfig(
            'product_id',
            'Product',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.products,
          ),
          _FieldConfig('name', 'Variant name', required: true),
          _FieldConfig('barcode', 'Barcode'),
          _FieldConfig(
            'cost_price',
            'Cost price',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'selling_price',
            'Selling price',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'stock_quantity',
            'Stock quantity',
            keyboardType: TextInputType.number,
          ),
        ],
        sample: [
          {
            'id': 1,
            'name': 'Rice 1kg',
            'product_id': 2,
            'selling_price': 720,
            'stock_quantity': 35,
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Customers',
        title: 'Credit customers',
        subtitle: 'Credit limit, balance, available credit and status.',
        endpoint: ApiRoutes.customers,
        icon: Icons.people_outline,
        color: _yellow,
        fields: const [
          _FieldConfig('name', 'Customer name', required: true),
          _FieldConfig('phone', 'Phone', keyboardType: TextInputType.phone),
          _FieldConfig(
            'email',
            'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          _FieldConfig('address', 'Address'),
          _FieldConfig(
            'credit_limit',
            'Credit limit',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'current_balance',
            'Current balance',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {
            'id': 1,
            'name': 'Tharindu Stores',
            'credit_limit': 50000,
            'current_balance': 12500,
            'status': 'active',
          },
          {
            'id': 2,
            'name': 'Colombo Mini Mart',
            'credit_limit': 35000,
            'current_balance': 8000,
            'status': 'active',
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Credit ledger',
        title: 'Customer credit transactions',
        subtitle: 'Credit sale, payment and adjustment ledger.',
        endpoint: ApiRoutes.customerCreditTransactions,
        icon: Icons.account_balance_wallet_outlined,
        color: _yellow,
        fields: const [
          _FieldConfig(
            'customer_id',
            'Customer',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.customers,
          ),
          _FieldConfig(
            'type',
            'Transaction type',
            options: [
              _FieldOption('credit_sale', 'Credit sale'),
              _FieldOption('payment', 'Payment'),
              _FieldOption('adjustment', 'Adjustment'),
            ],
          ),
          _FieldConfig(
            'amount',
            'Amount',
            keyboardType: TextInputType.number,
            required: true,
          ),
          _FieldConfig(
            'reference_id',
            'Reference',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig('remarks', 'Remarks'),
        ],
        sample: [
          {
            'id': 1,
            'customer_id': 1,
            'type': 'credit_sale',
            'amount': 12500,
            'reference_id': 1,
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Branches',
        title: 'Branches',
        subtitle: 'Branch name, code, contact details and status.',
        endpoint: ApiRoutes.branches,
        icon: Icons.store_mall_directory_outlined,
        color: _green,
        fields: const [
          _FieldConfig('name', 'Branch name', required: true),
          _FieldConfig('code', 'Branch code'),
          _FieldConfig('phone', 'Phone', keyboardType: TextInputType.phone),
          _FieldConfig(
            'email',
            'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          _FieldConfig('address', 'Address'),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {
            'id': 1,
            'name': 'Main Branch',
            'code': 'MAIN',
            'phone': '0777123456',
            'status': true,
          },
        ],
      ),
      _ResourceConfig(
        tab: 'Roles',
        title: 'Roles',
        subtitle: 'Backend roles used by cashiers, admins and managers.',
        endpoint: ApiRoutes.roles,
        icon: Icons.admin_panel_settings_outlined,
        color: _pink,
        fields: const [
          _FieldConfig('name', 'Role name', required: true),
          _FieldConfig('role_name', 'Role display name'),
          _FieldConfig('description', 'Description'),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        sample: [
          {'id': 1, 'name': 'Cashier', 'role_name': 'Cashier', 'status': true},
        ],
      ),
      _ResourceConfig(
        tab: 'Users',
        title: 'Backend users',
        subtitle: 'View authenticated backend users and cashier accounts.',
        endpoint: ApiRoutes.authUsers,
        icon: Icons.verified_user_outlined,
        color: _blue,
        fields: const [],
        canCreate: false,
        canEdit: false,
        canDelete: false,
        sample: [
          {
            'id': 1,
            'name': 'Super Admin',
            'phone': '0777123456',
            'role_name': 'Super Admin',
            'status': true,
          },
        ],
      ),
      _ResourceConfig(
        tab: 'POS sales',
        title: 'POS sales',
        subtitle: 'Create sales and update order/payment status.',
        endpoint: ApiRoutes.posSales,
        icon: Icons.point_of_sale,
        color: _blue,
        fields: const [
          _FieldConfig('sale_no', 'Sale number'),
          _FieldConfig(
            'customer_id',
            'Customer',
            keyboardType: TextInputType.number,
            lookupEndpoint: ApiRoutes.customers,
          ),
          _FieldConfig(
            'cashier_id',
            'Cashier',
            keyboardType: TextInputType.number,
            lookupEndpoint: ApiRoutes.authUsers,
          ),
          _FieldConfig('register_no', 'Register number'),
          _FieldConfig('shift_no', 'Shift number'),
          _FieldConfig(
            'subtotal',
            'Subtotal',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'discount_total',
            'Discount total',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'tax_total',
            'Tax total',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'grand_total',
            'Grand total',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'paid_amount',
            'Paid amount',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'balance_amount',
            'Balance amount',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'status',
            'Status',
            options: [
              _FieldOption('held', 'Held'),
              _FieldOption('completed', 'Completed'),
              _FieldOption('cancelled', 'Cancelled'),
              _FieldOption('refunded', 'Refunded'),
            ],
          ),
          _FieldConfig('notes', 'Notes'),
        ],
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canUpdateStatus: true,
        sample: [
          {
            'id': 1,
            'sale_no': 'SALE-001',
            'payment_method': 'cash',
            'grand_total': 3870,
            'status': 'completed',
          },
        ],
      ),
      _ResourceConfig.report(),
      _ResourceConfig.settings(),
    ];
  }

  _ResourceConfig _simpleResource(
    String tab,
    String title,
    String subtitle,
    String endpoint,
    IconData icon,
    Color color,
  ) {
    return _ResourceConfig(
      tab: tab,
      title: title,
      subtitle: subtitle,
      endpoint: endpoint,
      icon: icon,
      color: color,
      fields: const [
        _FieldConfig('name', 'Name', required: true),
        _FieldConfig('description', 'Description'),
        _FieldConfig('status', 'Status', options: _statusOptions),
      ],
      sample: [
        {
          'id': 1,
          'name': tab == 'Categories' ? 'Dairy' : 'Local Fresh',
          'description': subtitle,
          'status': true,
        },
      ],
    );
  }

  Future<void> _loadActiveTab() async {
    final resource = _activeResource;
    setState(() {
      _isLoading = true;
      _error = null;
      _records = [];
      _reportPayload = null;
      _settingsPayloads = {};
    });

    if (resource.kind == _ResourceKind.settings) {
      await _loadSettings();
      return;
    }

    try {
      if (resource.kind == _ResourceKind.report) {
        await _loadReport(ApiRoutes.reportSummary);
      } else {
        final response = await _dio.get(resource.endpoint);
        final rows = _extractRows(response.data);
        setState(() => _records = rows);
      }
    } catch (error) {
      setState(() {
        _error = _messageFor(error);
        _records = resource.sample;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSettings() async {
    try {
      final responses = await Future.wait([
        _dio.get(ApiRoutes.posSettings),
        _dio.get(ApiRoutes.posSettingsPaymentMethods),
        _dio.get(ApiRoutes.posSettingsReceipt),
        _dio.get(ApiRoutes.posSettingsDiscountRules),
      ]);
      setState(() {
        _settingsPayloads = {
          'General': _asMap(responses[0].data),
          'Payment methods': _asMap(responses[1].data),
          'Receipt': _asMap(responses[2].data),
          'Discount rules': _asMap(responses[3].data),
        };
      });
    } catch (error) {
      setState(() {
        _error = _messageFor(error);
        _settingsPayloads = {
          'General': {
            'endpoint': ApiRoutes.posSettings,
            'status': 'unavailable',
          },
          'Payment methods': {
            'endpoint': ApiRoutes.posSettingsPaymentMethods,
            'enabled': ['Cash', 'Card', 'Credit'],
          },
          'Receipt': {
            'endpoint': ApiRoutes.posSettingsReceipt,
            'footer': 'Thank you for shopping with NOVA POS',
          },
          'Discount rules': {
            'endpoint': ApiRoutes.posSettingsDiscountRules,
            'rules': [],
          },
        };
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReport(String endpoint) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _reportPayload = null;
    });

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'start_date': null,
          'end_date': null,
          'branch_id': null,
          'cashier_id': null,
          'customer_id': null,
          'product_id': null,
          'category_id': null,
          'payment_method': null,
          'status': null,
        }..removeWhere((_, value) => value == null || value == ''),
      );
      setState(() => _reportPayload = _asMap(response.data));
    } catch (error) {
      setState(() {
        _error = _messageFor(error);
        _reportPayload = {
          'message': 'Report API unavailable',
          'endpoint': endpoint,
          'common_query_params':
              'start_date, end_date, branch_id, cashier_id, customer_id, product_id, category_id, payment_method, status',
        };
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    const rowKeys = [
      'data',
      'rows',
      'items',
      'products',
      'categories',
      'brands',
      'units',
      'suppliers',
      'product_suppliers',
      'productSuppliers',
      'stock_movements',
      'stockMovements',
      'product_batches',
      'productBatches',
      'product_images',
      'productImages',
      'product_variants',
      'productVariants',
      'taxes',
      'discounts',
      'sales',
      'pos_sales',
      'posSales',
      'customers',
      'customer_credit_transactions',
      'customerCreditTransactions',
      'branches',
      'roles',
      'users',
      'backend_users',
      'backendUsers',
      'records',
    ];

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (payload is Map) {
      for (final key in rowKeys) {
        final value = payload[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
        if (value is Map) {
          for (final nested in rowKeys) {
            final nestedValue = value[nested];
            if (nestedValue is List) {
              return nestedValue
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            }
          }
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {'data': payload};
  }

  String _messageFor(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (status != null) return 'API $status: ${data ?? error.message}';
      return error.message ?? 'Network request failed';
    }
    return error.toString();
  }

  String? _recordId(Map<String, dynamic> record) {
    for (final key in [
      'id',
      '_id',
      'product_id',
      'category_id',
      'brand_id',
      'unit_id',
      'supplier_id',
      'customer_id',
      'branch_id',
      'role_id',
      'user_id',
      'backend_user_id',
      'sale_id',
    ]) {
      final value = record[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return null;
  }

  Future<void> _saveRecord(
    _ResourceConfig resource,
    Map<String, dynamic>? existing,
    Map<String, dynamic> data,
  ) async {
    final id = existing == null ? null : _recordId(existing);
    try {
      setState(() => _isLoading = true);
      if (existing == null) {
        await _dio.post(resource.endpoint, data: data);
      } else {
        await _dio.put('${resource.endpoint}/$id', data: data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(
        existing == null ? '${resource.tab} added' : '${resource.tab} updated',
      );
      await _loadActiveTab();
    } catch (error) {
      _showSnack(_messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord(
    _ResourceConfig resource,
    Map<String, dynamic> record,
  ) async {
    final id = _recordId(record);
    if (id == null) {
      _showSnack(
        'Cannot delete this record because it has no id.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${resource.tab}'),
        content: Text('Delete ${_titleFor(record)}?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      await _dio.delete('${resource.endpoint}/$id');
      _showSnack('${resource.tab} deleted');
      await _loadActiveTab();
    } catch (error) {
      _showSnack(_messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSaleStatus(Map<String, dynamic> record) async {
    final id = _recordId(record);
    if (id == null) {
      _showSnack('Sale id missing.', isError: true);
      return;
    }
    final controller = TextEditingController(
      text: record['status']?.toString() ?? 'completed',
    );
    final status = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update sale status'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Status'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (status == null || status.isEmpty) return;

    try {
      setState(() => _isLoading = true);
      await _dio.put(
        '${ApiRoutes.posSales}/$id/status',
        data: {'status': status},
      );
      _showSnack('Sale status updated');
      await _loadActiveTab();
    } catch (error) {
      _showSnack(_messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : _green,
      ),
    );
  }

  Future<void> _editSettingsEndpoint(
    String title,
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(payload),
    );
    final edited = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit $title',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      labelText: 'JSON payload',
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      try {
                        final decoded = jsonDecode(controller.text);
                        if (decoded is! Map) {
                          throw const FormatException(
                            'Root must be an object.',
                          );
                        }
                        Navigator.pop(
                          context,
                          Map<String, dynamic>.from(decoded),
                        );
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invalid JSON: $error'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save settings'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (edited == null) return;

    try {
      setState(() => _isLoading = true);
      await _dio.put(endpoint, data: edited);
      _showSnack('$title updated');
      await _loadSettings();
    } catch (error) {
      _showSnack(_messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDetails(_ResourceConfig resource, Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...record.entries.map(
                  (entry) => _DetailRow(
                    label: _label(entry.key),
                    value: _display(entry.value),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showForm(
    _ResourceConfig resource, {
    Map<String, dynamic>? record,
  }) async {
    final lookupOptions = <String, List<_LookupOption>>{};
    for (final field in resource.fields) {
      final endpoint = field.lookupEndpoint;
      if (endpoint != null) {
        lookupOptions[field.key] = await _lookupOptions(endpoint);
      }
    }
    if (!mounted) return;

    final controllers = {
      for (final field in resource.fields)
        field.key: TextEditingController(
          text: _initialFieldText(field, record),
        ),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: resource.color.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(resource.icon, color: resource.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record == null
                                    ? 'Add ${resource.tab}'
                                    : 'Update ${resource.tab}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                resource.subtitle,
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
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      children: [
                        if (resource.tab == 'Products')
                          const _FormHintCard(
                            message:
                                'Choose category, brand and unit by name. The app will send the correct IDs to the backend.',
                          ),
                        ...resource.fields.map((field) {
                          final fieldOptions = field.options
                              .map(
                                (option) => _LookupOption(
                                  value: option.value,
                                  label: option.label,
                                ),
                              )
                              .toList();
                          return _FormInput(
                            label: field.label,
                            controller: controllers[field.key]!,
                            keyboardType: field.keyboardType,
                            required: field.required,
                            options: lookupOptions[field.key] ?? fieldOptions,
                          );
                        }),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final data = <String, dynamic>{};
                          for (final field in resource.fields) {
                            final value = controllers[field.key]!.text.trim();
                            if (field.required && value.isEmpty) {
                              _showSnack(
                                '${field.label} is required',
                                isError: true,
                              );
                              return;
                            }
                            if (value.isNotEmpty) {
                              data[field.key] = _fieldValue(field, value);
                            }
                          }
                          _saveRecord(resource, record, data);
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text(record == null ? 'Save' : 'Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: resource.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future<void>.delayed(const Duration(seconds: 1), () {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      });
    });
  }

  String _initialFieldText(_FieldConfig field, Map<String, dynamic>? record) {
    if (record == null) return '';

    final directValue = record[field.key];
    if (directValue != null && directValue.toString().isNotEmpty) {
      return directValue.toString();
    }

    if (field.key.endsWith('_id')) {
      final relationKey = field.key.substring(0, field.key.length - 3);
      final relation = record[relationKey];
      if (relation is Map) {
        final id = _recordId(Map<String, dynamic>.from(relation));
        if (id != null) return id;
      }
    }

    return '';
  }

  Future<List<_LookupOption>> _lookupOptions(String endpoint) async {
    final cached = _lookupCache[endpoint];
    if (cached != null) return cached;

    try {
      final response = await _dio.get(endpoint);
      final options = _extractRows(response.data)
          .map((record) {
            final id = _recordId(record);
            if (id == null) return null;
            return _LookupOption(value: id, label: _lookupLabel(record));
          })
          .nonNulls
          .toList();
      _lookupCache[endpoint] = options;
      return options;
    } catch (_) {
      return const [];
    }
  }

  String _lookupLabel(Map<String, dynamic> record) {
    final value = _firstValue(record, [
      'name',
      'title',
      'short_name',
      'code',
      'product_code',
      'sku',
      'phone',
      'id',
    ]);
    return _display(value);
  }

  dynamic _typedValue(String value, TextInputType keyboardType) {
    if (keyboardType == TextInputType.number) {
      return num.tryParse(value) ?? value;
    }
    return value;
  }

  dynamic _fieldValue(_FieldConfig field, String value) {
    if (field.key == 'status' || field.key.startsWith('is_')) {
      final lower = value.toLowerCase();
      if (['true', '1', 'yes', 'active', 'enabled'].contains(lower)) {
        return true;
      }
      if (['false', '0', 'no', 'inactive', 'disabled'].contains(lower)) {
        return false;
      }
    }
    return _typedValue(value, field.keyboardType);
  }

  String _label(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  String _display(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Active' : 'Inactive';
    if (value is Map) return _nestedName(value);
    if (value is List) {
      return '${value.length} item${value.length == 1 ? '' : 's'}';
    }
    return value.toString();
  }

  String _nestedName(Map<dynamic, dynamic> value) {
    for (final key in [
      'name',
      'sale_no',
      'product_code',
      'phone',
      'email',
      'id',
    ]) {
      final nested = value[key];
      if (nested != null && nested.toString().isNotEmpty) {
        return nested.toString();
      }
    }
    return value.toString();
  }

  dynamic _firstValue(Map<String, dynamic> record, List<String> keys) {
    for (final key in keys) {
      final value = record[key];
      if (value != null && value.toString().isNotEmpty) return value;
    }
    return null;
  }

  String _titleFor(Map<String, dynamic> record) {
    final relationTitle = _firstValue(record, [
      'name',
      'title',
      'sale_no',
      'invoice_no',
      'batch_no',
      'product_code',
      'sku',
      'type',
      'id',
    ]);
    if (relationTitle != null) return _display(relationTitle);

    for (final key in ['product', 'supplier', 'customer', 'cashier']) {
      final value = record[key];
      if (value is Map) return _nestedName(value);
    }
    return 'Record';
  }

  String _subtitleFor(Map<String, dynamic> record) {
    final preferred = [
      'product_code',
      'sku',
      'code',
      'role_name',
      'username',
      'email',
      'phone',
      'description',
      'status',
      'discount_type',
      'method',
      'reference_id',
      'remarks',
      'created_at',
    ];
    final parts = <String>[];
    for (final key in preferred) {
      final value = record[key];
      if (value != null && value.toString().isNotEmpty) {
        parts.add('${_label(key)}: ${_display(value)}');
      }
      if (parts.length == 2) break;
    }
    if (parts.isNotEmpty) return parts.join(' / ');
    return record.entries
        .take(2)
        .map((entry) => '${_label(entry.key)}: ${_display(entry.value)}')
        .join(' / ');
  }

  String _trailingFor(Map<String, dynamic> record) {
    for (final key in [
      'selling_price',
      'grand_total',
      'amount',
      'current_balance',
      'stock_quantity',
      'quantity',
      'percentage',
      'value',
      'status',
      'code',
      'role_name',
    ]) {
      final value = record[key];
      if (value != null && value.toString().isNotEmpty) return _display(value);
    }
    return '#${_recordId(record) ?? '-'}';
  }

  @override
  Widget build(BuildContext context) {
    final resource = _activeResource;

    return AppBackScope(
      fallbackRoute: '/mainNavigation',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              const ManagementHeader(),
              ManagementTabs(
                tabs: _tabs,
                activeTab: _activeTab,
                onChanged: (value) {
                  setState(() => _activeTab = value);
                  _loadActiveTab();
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadActiveTab,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _SectionTitle(title: resource.tab),
                      const SizedBox(height: 12),
                      ManagementOptionCard(
                        icon: resource.icon,
                        title: resource.title,
                        subtitle: resource.subtitle,
                        value: resource.kind == _ResourceKind.report
                            ? '9 reports'
                            : resource.kind == _ResourceKind.settings
                            ? 'Configure'
                            : '${_records.length} rows',
                        color: resource.color,
                      ),
                      if (_error != null) _ApiNotice(message: _error!),
                      if (_isLoading) const _LoadingCard(),
                      ..._buildSection(resource),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSection(_ResourceConfig resource) {
    if (resource.kind == _ResourceKind.settings) return _settingsCards();
    if (resource.kind == _ResourceKind.report) return _reportCards();

    return [
      if (resource.canCreate) ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showForm(resource),
            icon: const Icon(Icons.add),
            label: Text('Add ${resource.tab}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: resource.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (!_isLoading && _records.isEmpty)
        _EmptyCard(
          title: 'No ${resource.tab.toLowerCase()} found',
          subtitle: 'Pull to refresh or add a new record.',
        ),
      ..._records.map(
        (record) => _ResourceActionCard(
          icon: resource.icon,
          title: _titleFor(record),
          subtitle: _subtitleFor(record),
          trailing: _trailingFor(record),
          onView: () => _showDetails(resource, record),
          onEdit: resource.canEdit
              ? () => _showForm(resource, record: record)
              : null,
          onDelete: resource.canDelete
              ? () => _deleteRecord(resource, record)
              : null,
          extraAction: resource.canUpdateStatus
              ? IconButton(
                  tooltip: 'Update status',
                  onPressed: () => _updateSaleStatus(record),
                  icon: const Icon(Icons.flag_outlined, color: _blue),
                )
              : null,
        ),
      ),
    ];
  }

  List<Widget> _reportCards() {
    final reports = [
      _ReportConfig(
        'Summary',
        ApiRoutes.reportSummary,
        Icons.dashboard_outlined,
      ),
      _ReportConfig('Sales', ApiRoutes.reportSales, Icons.receipt_long),
      _ReportConfig('Cashiers', ApiRoutes.reportCashiers, Icons.badge_outlined),
      _ReportConfig(
        'Products',
        ApiRoutes.reportProducts,
        Icons.inventory_2_outlined,
      ),
      _ReportConfig('Items', ApiRoutes.reportItems, Icons.list_alt_outlined),
      _ReportConfig(
        'Inventory',
        ApiRoutes.reportInventory,
        Icons.warehouse_outlined,
      ),
      _ReportConfig(
        'Payments',
        ApiRoutes.reportPayments,
        Icons.payments_outlined,
      ),
      _ReportConfig(
        'Tax discounts',
        ApiRoutes.reportTaxDiscounts,
        Icons.percent,
      ),
      _ReportConfig(
        'Credit',
        ApiRoutes.reportCredit,
        Icons.account_balance_wallet_outlined,
      ),
    ];

    return [
      _QueryHintCard(),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: reports.map((report) {
          return ActionChip(
            avatar: Icon(report.icon, size: 18, color: _blue),
            label: Text(report.label),
            onPressed: () => _loadReport(report.endpoint),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      if (_reportPayload != null) _ReportPayloadCard(payload: _reportPayload!),
    ];
  }

  List<Widget> _settingsCards() {
    final cards = [
      _SettingsEndpointConfig(
        'General',
        ApiRoutes.posSettings,
        Icons.settings_outlined,
      ),
      _SettingsEndpointConfig(
        'Payment methods',
        ApiRoutes.posSettingsPaymentMethods,
        Icons.payments_outlined,
      ),
      _SettingsEndpointConfig(
        'Receipt',
        ApiRoutes.posSettingsReceipt,
        Icons.receipt_long,
      ),
      _SettingsEndpointConfig(
        'Discount rules',
        ApiRoutes.posSettingsDiscountRules,
        Icons.discount_outlined,
      ),
    ];

    return [
      ...cards.map((config) {
        final payload = _settingsPayloads[config.title] ?? const {};
        return _SettingsApiCard(
          icon: config.icon,
          title: config.title,
          endpoint: config.endpoint,
          payload: payload,
          onEdit: () =>
              _editSettingsEndpoint(config.title, config.endpoint, payload),
        );
      }),
      _SettingsTile(
        icon: Icons.sync,
        title: 'API sync',
        subtitle: 'Uses /api catalog, stock, sales, settings and report APIs',
        trailing: const Icon(Icons.verified, color: _green),
      ),
    ];
  }
}

enum _ResourceKind { crud, report, settings }

class _ResourceConfig {
  final String tab;
  final String title;
  final String subtitle;
  final String endpoint;
  final IconData icon;
  final Color color;
  final List<_FieldConfig> fields;
  final List<Map<String, dynamic>> sample;
  final _ResourceKind kind;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canUpdateStatus;

  const _ResourceConfig({
    required this.tab,
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.icon,
    required this.color,
    required this.fields,
    required this.sample,
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.canUpdateStatus = false,
  }) : kind = _ResourceKind.crud;

  const _ResourceConfig.report()
    : tab = 'Reports',
      title = 'POS reports',
      subtitle =
          'Sales, cashiers, products, items, inventory, payments, tax and credit.',
      endpoint = '',
      icon = Icons.bar_chart,
      color = const Color(0xFF2F80ED),
      fields = const [],
      sample = const [],
      kind = _ResourceKind.report,
      canCreate = false,
      canEdit = false,
      canDelete = false,
      canUpdateStatus = false;

  const _ResourceConfig.settings()
    : tab = 'Settings',
      title = 'POS settings',
      subtitle = 'Payment methods, discount rules and receipt settings.',
      endpoint = '',
      icon = Icons.settings_outlined,
      color = const Color(0xFF111827),
      fields = const [],
      sample = const [],
      kind = _ResourceKind.settings,
      canCreate = false,
      canEdit = false,
      canDelete = false,
      canUpdateStatus = false;
}

class _FieldConfig {
  final String key;
  final String label;
  final TextInputType keyboardType;
  final bool required;
  final String? lookupEndpoint;
  final List<_FieldOption> options;

  const _FieldConfig(
    this.key,
    this.label, {
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.lookupEndpoint,
    this.options = const [],
  });
}

class _FieldOption {
  final String value;
  final String label;

  const _FieldOption(this.value, this.label);
}

class _LookupOption {
  final String value;
  final String label;

  const _LookupOption({required this.value, required this.label});
}

class _ReportConfig {
  final String label;
  final String endpoint;
  final IconData icon;

  const _ReportConfig(this.label, this.endpoint, this.icon);
}

class _SettingsEndpointConfig {
  final String title;
  final String endpoint;
  final IconData icon;

  const _SettingsEndpointConfig(this.title, this.endpoint, this.icon);
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _ApiNotice extends StatelessWidget {
  final String message;

  const _ApiNotice({required this.message});

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
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ResourceActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? extraAction;

  const _ResourceActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                child: Icon(icon, color: const Color(0xFF2F80ED)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
              ),
              if (extraAction != null) extraAction!,
            ],
          ),
        ],
      ),
    );
  }
}

class _QueryHintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: const Text(
        'Common report filters: start_date, end_date, branch_id, cashier_id, customer_id, product_id, category_id, payment_method, status.',
        style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReportPayloadCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const _ReportPayloadCard({required this.payload});

  @override
  Widget build(BuildContext context) {
    final entries = payload.entries.take(24).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report result',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => _ReportEntry(label: entry.key, value: entry.value),
          ),
        ],
      ),
    );
  }
}

class _ReportEntry extends StatelessWidget {
  final String label;
  final dynamic value;

  const _ReportEntry({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value is List) {
      final rows = (value as List).take(8).toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prettyLabel(label),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text('-', style: TextStyle(color: Color(0xFF6B7280)))
            else
              ...rows.map((row) => _ReportListRow(value: row)),
          ],
        ),
      );
    }

    if (value is Map) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prettyLabel(label),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            ...(value as Map).entries
                .take(12)
                .map(
                  (entry) => _DetailRow(
                    label: _prettyLabel(entry.key.toString()),
                    value: _simpleDisplay(entry.value),
                  ),
                ),
          ],
        ),
      );
    }

    return _DetailRow(label: _prettyLabel(label), value: _simpleDisplay(value));
  }
}

class _ReportListRow extends StatelessWidget {
  final dynamic value;

  const _ReportListRow({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value is! Map) {
      return _SmallReportTile(title: _simpleDisplay(value));
    }

    final map = Map<dynamic, dynamic>.from(value as Map);
    final title = _firstReportValue(map, [
      'sale_no',
      'product_name',
      'cashier_name',
      'customer_name',
      'method',
      'name',
      'product_code',
      'id',
    ]);
    final subtitle = map.entries
        .where(
          (entry) => entry.value != null && entry.value.toString().isNotEmpty,
        )
        .take(3)
        .map(
          (entry) =>
              '${_prettyLabel(entry.key.toString())}: ${_simpleDisplay(entry.value)}',
        )
        .join(' / ');

    return _SmallReportTile(
      title: title == null ? 'Record' : _simpleDisplay(title),
      subtitle: subtitle,
    );
  }
}

class _SmallReportTile extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SmallReportTile({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsApiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String endpoint;
  final Map<String, dynamic> payload;
  final VoidCallback onEdit;

  const _SettingsApiCard({
    required this.icon,
    required this.title,
    required this.endpoint,
    required this.payload,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final preview = payload.isEmpty
        ? 'No settings loaded yet'
        : const JsonEncoder.withIndent('  ').convert(payload);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                child: Icon(icon, color: const Color(0xFF2F80ED)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      endpoint,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit settings',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              preview,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEFF6FF),
            child: Icon(icon, color: const Color(0xFF2F80ED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool required;
  final List<_LookupOption> options;

  const _FormInput({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.required,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final menuOptions = options.isNotEmpty ? options : const <_LookupOption>[];

    if (menuOptions.isNotEmpty) {
      final selected =
          menuOptions.any((option) => option.value == controller.text)
          ? controller.text
          : null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: menuOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            controller.text = value ?? '';
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _FormHintCard extends StatelessWidget {
  final String message;

  const _FormHintCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2F80ED), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Theme.of(context).dividerColor),
  );
}

String _prettyLabel(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

String _simpleDisplay(dynamic value) {
  if (value == null) return '-';
  if (value is bool) return value ? 'Active' : 'Inactive';
  if (value is List) {
    return '${value.length} item${value.length == 1 ? '' : 's'}';
  }
  if (value is Map) {
    final nested = _firstReportValue(value, [
      'name',
      'sale_no',
      'product_name',
      'customer_name',
      'cashier_name',
      'product_code',
      'id',
    ]);
    return nested == null ? value.toString() : nested.toString();
  }
  return value.toString();
}

dynamic _firstReportValue(Map<dynamic, dynamic> record, List<String> keys) {
  for (final key in keys) {
    final value = record[key];
    if (value != null && value.toString().isNotEmpty) return value;
  }
  return null;
}
