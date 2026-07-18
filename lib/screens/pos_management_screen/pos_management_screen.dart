import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'widgets/management_header.dart';
import 'widgets/management_option_card.dart';
import 'widgets/management_tabs.dart';
import 'package:mpos/utils/custom_snackbar.dart';

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
  String _activeReportLabel = 'Summary';
  String _activeReportEndpoint = ApiRoutes.reportSummary;
  Map<String, Map<String, dynamic>> _settingsPayloads = {};
  final Map<String, List<_LookupOption>> _lookupCache = {};
  String _stockMovementSearch = '';

  static const _green = Color(0xFF059669);
  static const _blue = Color(0xFF2563EB);
  static const _yellow = Color(0xFFD97706);
  static const _pink = Color(0xFF7C3AED);

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSuperAdmin = authProvider.isSuperAdmin;

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
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
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
            'stock_after',
            'Stock after',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig(
            'reference_id',
            'Reference ID',
            keyboardType: TextInputType.number,
          ),
          _FieldConfig('reference_no', 'Reference no'),
          _FieldConfig('remarks', 'Remarks'),
        ],
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
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
        sample: [],
      ),
      _ResourceConfig(
        tab: 'Users',
        title: 'Backend users',
        subtitle: 'View authenticated backend users and cashier accounts.',
        endpoint: ApiRoutes.authUsers,
        icon: Icons.verified_user_outlined,
        color: _blue,
        fields: const [
          _FieldConfig('name', 'Full name', required: true),
          _FieldConfig('phone', 'Phone', keyboardType: TextInputType.phone, required: true),
          _FieldConfig('email', 'Email', keyboardType: TextInputType.emailAddress, required: true),
          _FieldConfig('password', 'Password'),
          _FieldConfig(
            'role_id',
            'Role',
            keyboardType: TextInputType.number,
            required: true,
            lookupEndpoint: ApiRoutes.roles,
          ),
          _FieldConfig(
            'branch_id',
            'Branch',
            keyboardType: TextInputType.number,
            lookupEndpoint: ApiRoutes.branches,
          ),
          _FieldConfig('status', 'Status', options: _statusOptions),
        ],
        canCreate: isSuperAdmin,
        canEdit: isSuperAdmin,
        canDelete: isSuperAdmin,
        sample: [],
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
        sample: [],
      ),
      _ResourceConfig.report(),
      //_ResourceConfig.settings(),
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
        await _loadReport(ApiRoutes.reportSummary, label: 'Summary');
      } else {
        final response = await _dio.get(resource.endpoint);
        final rows = _extractRows(response.data);
        setState(() => _records = rows);
      }
    } catch (error) {
      setState(() {
        _error = _messageFor(error);
        _records = [];
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

  Future<void> _loadReport(String endpoint, {required String label}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _reportPayload = null;
      _activeReportLabel = label;
      _activeReportEndpoint = endpoint;
    });

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'from': null,
          'to': null,
          'status': null,
          'customer_id': null,
          'cashier_id': null,
          'register_session_id': null,
          'register_no': null,
          'shift_no': null,
          'sale_no': null,
          'recent_limit': null,
          'today_target': null,
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
              'from, to, status, customer_id, cashier_id, register_session_id, register_no, shift_no, sale_no, recent_limit, today_target',
        };
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReportPdf() async {
    final payload = _reportPayload;
    if (payload == null) {
      _showSnack('Load a report before downloading PDF', isError: true);
      return;
    }

    final pdf = _buildReportPdf(
      title: _activeReportLabel,
      endpoint: _activeReportEndpoint,
      payload: payload,
    );
    final filename =
        '${_activeReportLabel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-report.pdf';

    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  pw.Document _buildReportPdf({
    required String title,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) {
    final generatedAt = DateTime.now().toString().substring(0, 16);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            pw.Text(
              'NOVA POS',
              style: pw.TextStyle(
                fontSize: 13,
                color: PdfColors.blueGrey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '$title Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generated $generatedAt  |  /api/$endpoint',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),
            pw.Divider(height: 24),
            ...payload.entries
                .take(40)
                .map((entry) => _pdfReportEntry(entry.key, entry.value)),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfReportEntry(String label, dynamic value) {
    final title = _prettyLabel(label);

    if (value is List) {
      final rows = value.take(20).toList();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pdfSectionTitle(title),
          if (rows.isEmpty)
            pw.Text('-', style: const pw.TextStyle(fontSize: 10))
          else
            ...rows.map((row) => _pdfRecordBox(row)),
          pw.SizedBox(height: 10),
        ],
      );
    }

    if (value is Map) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pdfSectionTitle(title),
          ...value.entries
              .take(20)
              .map(
                (entry) => _pdfKeyValue(
                  _prettyLabel(entry.key.toString()),
                  _simpleDisplay(entry.value),
                ),
              ),
          pw.SizedBox(height: 10),
        ],
      );
    }

    return pw.Column(
      children: [
        _pdfKeyValue(title, _simpleDisplay(value)),
        pw.SizedBox(height: 5),
      ],
    );
  }

  pw.Widget _pdfRecordBox(dynamic value) {
    if (value is! Map) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 5),
        padding: const pw.EdgeInsets.all(8),
        color: PdfColors.blueGrey50,
        child: pw.Text(
          _simpleDisplay(value),
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    }

    final map = Map<dynamic, dynamic>.from(value);
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 5),
      padding: const pw.EdgeInsets.all(8),
      color: PdfColors.blueGrey50,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: map.entries
            .take(6)
            .map(
              (entry) => _pdfKeyValue(
                _prettyLabel(entry.key.toString()),
                _simpleDisplay(entry.value),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _pdfKeyValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
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
      builder: (_) {
        final theme = Theme.of(context);
        return AlertDialog(
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
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
    if (isError) {
      CustomSnackBar.error(context, message);
    } else {
      CustomSnackBar.success(context, message);
    }
  }

  Future<void> _editSettingsEndpoint(
    String title,
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    if (title == 'Payment methods') {
      final enabled = _enabledPaymentMethods(payload).toSet();
      final edited = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment methods',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/$endpoint',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...['Cash', 'Card', 'Credit', 'Wallet'].map((method) {
                        return SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(method),
                          value: enabled.contains(method),
                          onChanged: (value) {
                            setSheetState(() {
                              if (value) {
                                enabled.add(method);
                              } else {
                                enabled.remove(method);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: enabled.isEmpty
                              ? null
                              : () => Navigator.pop(context, {
                                  ...payload,
                                  'enabled': enabled.toList(),
                                  'enabled_methods': enabled
                                      .map((value) => value.toLowerCase())
                                      .toList(),
                                }),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save payment methods'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (edited != null) await _saveSettingsPayload(title, endpoint, edited);
      return;
    }

    final fields = _settingsFields(title);
    if (fields.isNotEmpty) {
      final controllers = {
        for (final field in fields)
          if (field.type != _SettingFieldType.boolean)
            field.key: TextEditingController(
              text: _settingText(payload, field.key, field.fallback),
            ),
      };
      final boolValues = {
        for (final field in fields)
          if (field.type == _SettingFieldType.boolean)
            field.key: _settingBool(payload, field.key, field.boolFallback),
      };

      final edited = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '/$endpoint',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...fields.map((field) {
                          if (field.type == _SettingFieldType.boolean) {
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(field.label),
                              value: boolValues[field.key] ?? false,
                              onChanged: (value) => setSheetState(
                                () => boolValues[field.key] = value,
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              controller: controllers[field.key],
                              keyboardType:
                                  field.type == _SettingFieldType.number
                                  ? TextInputType.number
                                  : TextInputType.text,
                              decoration: InputDecoration(
                                labelText: field.label,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final next = Map<String, dynamic>.from(payload);
                              for (final field in fields) {
                                if (field.type == _SettingFieldType.boolean) {
                                  next[field.key] =
                                      boolValues[field.key] ?? false;
                                  continue;
                                }

                                final text =
                                    controllers[field.key]?.text.trim() ?? '';
                                if (text.isEmpty) continue;
                                next[field.key] =
                                    field.type == _SettingFieldType.number
                                    ? num.tryParse(text) ?? text
                                    : text;
                              }
                              Navigator.pop(context, next);
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: Text('Save $title'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      for (final controller in controllers.values) {
        controller.dispose();
      }

      if (edited != null) await _saveSettingsPayload(title, endpoint, edited);
      return;
    }

    final controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(payload),
    );
    final edited = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
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
                        CustomSnackBar.error(context, 'Invalid JSON: $error');
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

    await _saveSettingsPayload(title, endpoint, edited);
  }

  Future<void> _saveSettingsPayload(
    String title,
    String endpoint,
    Map<String, dynamic> edited,
  ) async {
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

  List<String> _enabledPaymentMethods(Map<String, dynamic> payload) {
    final value =
        payload['enabled'] ??
        payload['enabled_methods'] ??
        payload['methods'] ??
        payload['payment_methods'];
    if (value is List) {
      return value.map((item) => _titleCase(item.toString())).toList();
    }
    return const ['Cash', 'Card', 'Credit'];
  }

  List<_SettingFieldConfig> _settingsFields(String title) {
    switch (title) {
      case 'General':
        return const [
          _SettingFieldConfig('currency', 'Currency', fallback: 'LKR'),
          _SettingFieldConfig(
            'default_tax_percent',
            'Default tax percent',
            type: _SettingFieldType.number,
          ),
          _SettingFieldConfig(
            'low_stock_alert_quantity',
            'Low stock alert quantity',
            type: _SettingFieldType.number,
          ),
          _SettingFieldConfig(
            'allow_hold_sales',
            'Allow hold sales',
            type: _SettingFieldType.boolean,
            boolFallback: true,
          ),
        ];
      case 'Receipt':
        return const [
          _SettingFieldConfig('store_name', 'Store name'),
          _SettingFieldConfig('receipt_title', 'Receipt title'),
          _SettingFieldConfig('footer', 'Footer message'),
          _SettingFieldConfig(
            'show_tax',
            'Show tax',
            type: _SettingFieldType.boolean,
            boolFallback: true,
          ),
          _SettingFieldConfig(
            'show_discount',
            'Show discount',
            type: _SettingFieldType.boolean,
            boolFallback: true,
          ),
          _SettingFieldConfig(
            'show_logo',
            'Show logo',
            type: _SettingFieldType.boolean,
          ),
        ];
      case 'Discount rules':
        return const [
          _SettingFieldConfig(
            'allow_manual_discount',
            'Allow manual discount',
            type: _SettingFieldType.boolean,
            boolFallback: true,
          ),
          _SettingFieldConfig(
            'max_discount_percent',
            'Max discount percent',
            type: _SettingFieldType.number,
          ),
          _SettingFieldConfig(
            'approval_required_above_percent',
            'Approval required above percent',
            type: _SettingFieldType.number,
          ),
        ];
      default:
        return const [];
    }
  }

  String _settingText(
    Map<String, dynamic> payload,
    String key,
    String fallback,
  ) {
    final value = payload[key];
    if (value == null || value.toString().isEmpty) return fallback;
    return value.toString();
  }

  bool _settingBool(
    Map<String, dynamic> payload,
    String key,
    bool fallback,
  ) {
    final value = payload[key];
    if (value is bool) return value;
    if (value == null) return fallback;
    return ['true', '1', 'yes', 'active', 'enabled'].contains(
      value.toString().toLowerCase(),
    );
  }

  void _showDetails(_ResourceConfig resource, Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            resource.icon,
                            color: resource.color,
                            size: 21,
                          ),
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

  String _stockProductName(Map<String, dynamic> record) {
    final direct = _firstValue(record, [
      'product_name',
      'product',
      'name',
      'item_name',
    ]);
    if (direct is Map) return _nestedName(direct);
    if (direct != null) return _display(direct);

    final product = record['product'];
    if (product is Map) return _nestedName(product);

    return 'Product #${_display(record['product_id'])}';
  }

  String _stockProductCode(Map<String, dynamic> record) {
    final direct = _firstValue(record, [
      'product_code',
      'sku',
      'barcode',
      'code',
    ]);
    if (direct != null) return _display(direct);

    final product = record['product'];
    if (product is Map) {
      final code = _firstValue(Map<String, dynamic>.from(product), [
        'product_code',
        'sku',
        'barcode',
        'code',
      ]);
      if (code != null) return _display(code);
    }

    return '-';
  }

  String _stockMovementType(Map<String, dynamic> record) {
    return _display(
      _firstValue(record, ['type', 'movement_type', 'method']),
    ).toLowerCase();
  }

  String _stockReference(Map<String, dynamic> record) {
    return _display(
      _firstValue(record, ['reference_no', 'reference', 'reference_id']),
    );
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
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
    if (resource.tab == 'Stock movements') {
      return _stockMovementCards(resource);
    }

    return [
      if (resource.canCreate) ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showForm(resource),
            icon: const Icon(Icons.add),
            label: Text('Add ${resource.tab}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 13),
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

  List<Widget> _stockMovementCards(_ResourceConfig resource) {
    final query = _stockMovementSearch.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _records
        : _records.where((record) {
            return [
              _stockProductName(record),
              _stockProductCode(record),
              _stockMovementType(record),
              _stockReference(record),
              _display(record['remarks']),
            ].any((value) => value.toLowerCase().contains(query));
          }).toList();

    return [
      _StockMovementPanel(
        records: filtered,
        allRecords: _records,
        endpoint: resource.endpoint,
        searchText: _stockMovementSearch,
        isLoading: _isLoading,
        onSearchChanged: (value) {
          setState(() => _stockMovementSearch = value);
        },
        onAdd: () => _showForm(resource),
        onView: (record) => _showDetails(resource, record),
        onEdit: resource.canEdit
            ? (record) => _showForm(resource, record: record)
            : null,
        onDelete: resource.canDelete
            ? (record) => _deleteRecord(resource, record)
            : null,
      ),
      if (!_isLoading && _records.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: _EmptyCard(
            title: 'No stock movements found',
            subtitle: 'Use Add movement to record inventory in or out.',
          ),
        ),
    ];
  }

  List<Widget> _reportCards() {
    final reports = [
      _ReportConfig(
        'Dashboard',
        ApiRoutes.dashboard,
        Icons.space_dashboard_outlined,
        'Metrics, chart, cashier summaries and recent sales',
      ),
      _ReportConfig(
        'Summary',
        ApiRoutes.reportSummary,
        Icons.dashboard_outlined,
        'Today at a glance',
      ),
      _ReportConfig(
        'Sales',
        ApiRoutes.reportSales,
        Icons.receipt_long,
        'Bills, totals and sale status',
      ),
      _ReportConfig(
        'Cashiers',
        ApiRoutes.reportCashiers,
        Icons.badge_outlined,
        'Performance by cashier',
      ),
      _ReportConfig(
        'Products',
        ApiRoutes.reportProducts,
        Icons.inventory_2_outlined,
        'Product movement and value',
      ),
      _ReportConfig(
        'Items',
        ApiRoutes.reportItems,
        Icons.list_alt_outlined,
        'Line items sold',
      ),
      _ReportConfig(
        'Inventory',
        ApiRoutes.reportInventory,
        Icons.warehouse_outlined,
        'Stock position and alerts',
      ),
      _ReportConfig(
        'Payments',
        ApiRoutes.reportPayments,
        Icons.payments_outlined,
        'Cash, card and other payments',
      ),
      _ReportConfig(
        'Tax discounts',
        ApiRoutes.reportTaxDiscounts,
        Icons.percent,
        'Taxes, discounts and adjustments',
      ),
      _ReportConfig(
        'Credit',
        ApiRoutes.reportCredit,
        Icons.account_balance_wallet_outlined,
        'Customer credit and balances',
      ),
    ];

    return [
      _QueryHintCard(),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: compact ? 1 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: compact ? 3.25 : 2.8,
            ),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportPickerCard(
                report: report,
                selected: report.endpoint == _activeReportEndpoint,
                onTap: () => _loadReport(report.endpoint, label: report.label),
              );
            },
          );
        },
      ),
      const SizedBox(height: 12),
      if (_reportPayload != null)
        _ReportPayloadCard(
          title: _activeReportLabel,
          endpoint: _activeReportEndpoint,
          payload: _reportPayload!,
          onDownload: () => _downloadReportPdf(),
        ),
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
  final String description;

  const _ReportConfig(this.label, this.endpoint, this.icon, this.description);
}

class _SettingsEndpointConfig {
  final String title;
  final String endpoint;
  final IconData icon;

  const _SettingsEndpointConfig(this.title, this.endpoint, this.icon);
}

enum _SettingFieldType { text, number, boolean }

class _SettingFieldConfig {
  final String key;
  final String label;
  final _SettingFieldType type;
  final String fallback;
  final bool boolFallback;

  const _SettingFieldConfig(
    this.key,
    this.label, {
    this.type = _SettingFieldType.text,
    this.fallback = '',
    this.boolFallback = false,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _ApiNotice extends StatelessWidget {
  final String message;

  const _ApiNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF92400E).withValues(alpha: 0.4) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
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

class _StockMovementPanel extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> allRecords;
  final String endpoint;
  final String searchText;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>>? onEdit;
  final ValueChanged<Map<String, dynamic>>? onDelete;

  const _StockMovementPanel({
    required this.records,
    required this.allRecords,
    required this.endpoint,
    required this.searchText,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onAdd,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stockIn = allRecords
        .where((record) => _isStockIn(_movementType(record)))
        .fold<double>(0, (sum, record) => sum + _quantity(record).abs());
    final stockOut = allRecords
        .where((record) => _isStockOut(_movementType(record)))
        .fold<double>(0, (sum, record) => sum + _quantity(record).abs());
    final adjustments = allRecords
        .where((record) => _movementType(record).contains('adjust'))
        .length;
    final productCount = allRecords
        .map(_productIdentity)
        .where((value) => value.isNotEmpty && value != '-')
        .toSet()
        .length;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock movements',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record inventory in, sales out, returns, and stock corrections.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.swap_vert, size: 18),
                label: const Text('Add movement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _StockPanelLink(icon: Icons.history, label: 'Movement history'),
              _StockPanelLink(
                icon: Icons.inventory_2_outlined,
                label: 'Remaining stock',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 64,
            runSpacing: 18,
            children: [
              _StockMetric(
                label: 'Movements',
                value: allRecords.length.toString(),
              ),
              _StockMetric(
                label: 'Stock in',
                value: '+${_formatNumber(stockIn)}',
              ),
              _StockMetric(
                label: 'Stock out',
                value: '-${_formatNumber(stockOut)}',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _StockInlineStat(
                label: 'Adjustments',
                value: adjustments.toString(),
              ),
              _StockInlineStat(label: 'Endpoint', value: '/$endpoint'),
              _StockInlineStat(
                label: 'Products tracked',
                value: productCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Search product, SKU, type, reference, or remarks',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
            controller: TextEditingController(text: searchText)
              ..selection = TextSelection.collapsed(offset: searchText.length),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const LinearProgressIndicator()
          else
            _StockMovementTable(
              records: records,
              onView: onView,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }

  static bool _isStockIn(String type) {
    return type.contains('purchase') ||
        type.contains('return') ||
        type.contains('in');
  }

  static bool _isStockOut(String type) {
    return type.contains('sale') ||
        type.contains('out') ||
        type.contains('damage') ||
        type.contains('loss');
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _StockMetric extends StatelessWidget {
  final String label;
  final String value;

  const _StockMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockInlineStat extends StatelessWidget {
  final String label;
  final String value;

  const _StockInlineStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockPanelLink extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StockPanelLink({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StockMovementTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>>? onEdit;
  final ValueChanged<Map<String, dynamic>>? onDelete;

  const _StockMovementTable({
    required this.records,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text(
          'No movements match the current search.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: WidgetStateProperty.all(isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFF102516)),
          dataRowColor: WidgetStateProperty.all(theme.cardTheme.color ?? theme.colorScheme.surface),
          headingTextStyle: TextStyle(
            color: isDark ? theme.colorScheme.onSurface : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
          dataTextStyle: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 12,
          ),
          columnSpacing: 36,
          columns: const [
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('PRODUCT')),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('QUANTITY')),
            DataColumn(label: Text('STOCK AFTER')),
            DataColumn(label: Text('REFERENCE')),
            DataColumn(label: Text('REMARKS')),
            DataColumn(label: Text('')),
          ],
          rows: records.map((record) {
            final type = _movementType(record);
            return DataRow(
              onSelectChanged: (_) => onView(record),
              cells: [
                DataCell(Text(_movementDate(record))),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _productName(record),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _productCode(record),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(_MovementTypeChip(type: type)),
                DataCell(
                  Text(
                    _formatSignedQuantity(record),
                    style: TextStyle(
                      color: _quantityColor(context, type),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                DataCell(Text(_display(_firstValue(record, ['stock_after'])))),
                DataCell(Text(_reference(record))),
                DataCell(
                  SizedBox(
                    width: 260,
                    child: Text(
                      _display(record['remarks']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'View movement',
                        onPressed: () => onView(record),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      if (onEdit != null)
                        IconButton(
                          tooltip: 'Edit movement',
                          onPressed: () => onEdit!(record),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF334155),
                            size: 18,
                          ),
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete movement',
                          onPressed: () => onDelete!(record),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFCA5A5),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MovementTypeChip extends StatelessWidget {
  final String type;

  const _MovementTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final stockIn = _StockMovementPanel._isStockIn(type);
    final color = stockIn ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        _titleCase(type),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: isDark ? colorScheme.primary : const Color(0xFF334155), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                trailing,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                  style: _rowButtonStyle(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: _rowButtonStyle(context),
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
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              ?extraAction,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a report to review',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a report card below. Filters such as date range, branch, cashier, customer, product, category, payment method and status can be sent by the API.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPickerCard extends StatelessWidget {
  final _ReportConfig report;
  final bool selected;
  final VoidCallback onTap;

  const _ReportPickerCard({
    required this.report,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: selected
          ? (isDark ? colorScheme.primary.withValues(alpha: 0.2) : const Color(0xFFDBEAFE))
          : (isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFEAF1FB)),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(report.icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportPayloadCard extends StatelessWidget {
  final String title;
  final String endpoint;
  final Map<String, dynamic> payload;
  final VoidCallback onDownload;

  const _ReportPayloadCard({
    required this.title,
    required this.endpoint,
    required this.payload,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final entries = payload.entries.take(24).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title report',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Download PDF',
                onPressed: onDownload,
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            endpoint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
    final theme = Theme.of(context);
    if (value is List) {
      final rows = (value as List).take(8).toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prettyLabel(label),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text('-', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))
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
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
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
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      endpoint,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Text(
              preview,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
        borderRadius: BorderRadius.circular(6),
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

dynamic _firstValue(Map<String, dynamic> record, List<String> keys) {
  for (final key in keys) {
    final value = record[key];
    if (value != null && value.toString().isNotEmpty) return value;
  }
  return null;
}

String _display(dynamic value) {
  if (value == null) return '-';
  if (value is bool) return value ? 'Active' : 'Inactive';
  if (value is Map) {
    return _display(
      _firstValue(Map<String, dynamic>.from(value), [
        'name',
        'sale_no',
        'product_code',
        'sku',
        'phone',
        'email',
        'id',
      ]),
    );
  }
  if (value is List) return '${value.length} items';
  return value.toString();
}

String _movementType(Map<String, dynamic> record) {
  return _display(
    _firstValue(record, ['type', 'movement_type', 'method']),
  ).toLowerCase();
}

double _quantity(Map<String, dynamic> record) {
  final value = _firstValue(record, ['quantity', 'qty', 'stock_quantity']);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _productName(Map<String, dynamic> record) {
  final direct = _firstValue(record, [
    'product_name',
    'product',
    'name',
    'item_name',
  ]);
  if (direct != null) return _display(direct);
  return 'Product #${_display(record['product_id'])}';
}

String _productCode(Map<String, dynamic> record) {
  final direct = _firstValue(record, [
    'product_code',
    'sku',
    'barcode',
    'code',
  ]);
  if (direct != null) return _display(direct);

  final product = record['product'];
  if (product is Map) {
    return _display(
      _firstValue(Map<String, dynamic>.from(product), [
        'product_code',
        'sku',
        'barcode',
        'code',
      ]),
    );
  }

  return '-';
}

String _productIdentity(Map<String, dynamic> record) {
  return _display(
    _firstValue(record, ['product_id', 'product_code', 'sku']) ??
        _productName(record),
  );
}

String _reference(Map<String, dynamic> record) {
  final value = _firstValue(record, [
    'reference_no',
    'reference',
    'reference_id',
    'sale_no',
  ]);
  final text = _display(value);
  return text == '-' ? '-' : '#$text';
}

String _movementDate(Map<String, dynamic> record) {
  final value = _firstValue(record, [
    'created_at',
    'date',
    'movement_date',
    'updated_at',
  ]);
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return _display(value);

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

String _formatSignedQuantity(Map<String, dynamic> record) {
  final type = _movementType(record);
  final amount = _quantity(record).abs();
  final text = _StockMovementPanel._formatNumber(amount);
  if (_StockMovementPanel._isStockOut(type)) return '-$text';
  if (_StockMovementPanel._isStockIn(type)) return '+$text';
  return _StockMovementPanel._formatNumber(_quantity(record));
}

Color _quantityColor(BuildContext context, String type) {
  final theme = Theme.of(context);
  if (_StockMovementPanel._isStockIn(type)) return const Color(0xFF10B981);
  if (_StockMovementPanel._isStockOut(type)) return const Color(0xFFF87171);
  return theme.colorScheme.onSurface;
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

BoxDecoration _cardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFFEAF1FB),
    borderRadius: BorderRadius.circular(8),
    border: isDark ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)) : null,
  );
}

ButtonStyle _rowButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return OutlinedButton.styleFrom(
    foregroundColor: colorScheme.onSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(vertical: 11),
    backgroundColor: colorScheme.surface,
    disabledBackgroundColor: colorScheme.surface.withValues(alpha: 0.5),
    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
