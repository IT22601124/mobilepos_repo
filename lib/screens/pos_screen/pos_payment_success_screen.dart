import 'package:mpos/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/provider/printing_provider.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:mpos/utils/receipt_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PosPaymentSuccessScreen extends StatefulWidget {
  final String saleNo;
  final String paymentMethod;
  final double subtotal;
  final double discount;
  final double tax;
  final double taxRate;
  final double total;
  final double paid;
  final double change;
  final double creditAmount;
  final String customerName;
  final List<Map<String, dynamic>> cart;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String receiptFooter;
  final String currencyCode;
  final String logoUrl;

  const PosPaymentSuccessScreen({
    super.key,
    required this.saleNo,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.taxRate,
    required this.total,
    required this.paid,
    required this.change,
    required this.creditAmount,
    required this.customerName,
    required this.cart,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.receiptFooter,
    required this.currencyCode,
    required this.logoUrl,
  });

  @override
  State<PosPaymentSuccessScreen> createState() => _PosPaymentSuccessScreenState();
}

class _PosPaymentSuccessScreenState extends State<PosPaymentSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAutoPrint();
    });
  }

  void _handleAutoPrint() {
    final printingProvider = context.read<PrintingProvider>();
    if (printingProvider.autoPrint && printingProvider.isConnected(PrinterRole.receipt)) {
      printReceipt(context);
    }
  }

  String money(double value) => '${widget.currencyCode} ${value.toStringAsFixed(0)}';

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> printReceipt(BuildContext context) async {
    final printingProvider = context.read<PrintingProvider>();
    final logoBytes = printingProvider.logoBytes;

    final data = ReceiptData(
      saleNo: widget.saleNo,
      date: DateTime.now().toString().substring(0, 16),
      customerName: widget.customerName,
      paymentMethod: widget.paymentMethod,
      items: widget.cart,
      subtotal: widget.subtotal,
      discount: widget.discount,
      tax: widget.tax,
      taxRate: widget.taxRate,
      total: widget.total,
      paid: widget.paid,
      change: widget.change,
      creditAmount: widget.creditAmount,
      storeName: widget.storeName,
      storeAddress: widget.storeAddress,
      storePhone: widget.storePhone,
      receiptFooter: widget.receiptFooter,
      currencyCode: widget.currencyCode,
      logoBytes: logoBytes,
    );

    if (printingProvider.isConnected(PrinterRole.receipt)) {
      final profile = await CapabilityProfile.load();
      final bytes = await ReceiptUtils.generateThermalBytes(
        data: data,
        paperSize: printingProvider.paperSize(PrinterRole.receipt),
        profile: profile,
        context: context,
      );
      await printingProvider.sendReceiptBytes(bytes);
    } else {
      final pdf = ReceiptUtils.generatePdfReceipt(
        data: data,
        widthMm: printingProvider.paperWidthMm(PrinterRole.receipt).toDouble(),
        context: context,
      );
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    }
  }

  Future<void> sharePdfReceipt() async {
    final printingProvider = context.read<PrintingProvider>();
    final logoBytes = printingProvider.logoBytes;
    
    final data = ReceiptData(
      saleNo: widget.saleNo,
      date: DateTime.now().toString().substring(0, 16),
      customerName: widget.customerName,
      paymentMethod: widget.paymentMethod,
      items: widget.cart,
      subtotal: widget.subtotal,
      discount: widget.discount,
      tax: widget.tax,
      taxRate: widget.taxRate,
      total: widget.total,
      paid: widget.paid,
      change: widget.change,
      creditAmount: widget.creditAmount,
      storeName: widget.storeName,
      storeAddress: widget.storeAddress,
      storePhone: widget.storePhone,
      receiptFooter: widget.receiptFooter,
      currencyCode: widget.currencyCode,
      logoBytes: logoBytes,
    );

    final pdf = ReceiptUtils.generatePdfReceipt(
      data: data,
      widthMm: 80,
      context: context,
    );
    final pdfBytes = await pdf.save();

    await Printing.sharePdf(bytes: pdfBytes, filename: '${widget.saleNo}-receipt.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppBackScope(
      fallbackRoute: '/pos_terminal',
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => context.go('/pos_terminal'),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 38,
              backgroundColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFEAFBF1),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 54,
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: Text(
                context.tr('payment_success'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Center(
              child: Text(
                widget.saleNo,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _ReceiptCard(
              saleNo: widget.saleNo,
              paymentMethod: widget.paymentMethod,
              customerName: widget.customerName,
              storeName: widget.storeName,
              storeAddress: widget.storeAddress,
              storePhone: widget.storePhone,
              receiptFooter: widget.receiptFooter,
              currencyCode: widget.currencyCode,
              logoUrl: widget.logoUrl,
              subtotal: widget.subtotal,
              discount: widget.discount,
              tax: widget.tax,
              taxRate: widget.taxRate,
              total: widget.total,
              paid: widget.paid,
              change: widget.change,
              creditAmount: widget.creditAmount,
              cart: widget.cart,
            ),

            const SizedBox(height: 20),

            // Receipt Actions Section
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: sharePdfReceipt,
                    icon: const Icon(Icons.share_rounded),
                    label: Text(context.tr('share')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => printReceipt(context),
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(context.tr('download')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => printReceipt(context),
              icon: const Icon(Icons.print_rounded),
              label: const Text('Print Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),
            
            const Divider(),

            const SizedBox(height: 10),

            TextButton.icon(
              onPressed: () => context.go('/pos_terminal'),
              icon: const Icon(Icons.point_of_sale),
              label: Text(context.tr('start_new_sale')),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final String saleNo;
  final String paymentMethod;
  final String customerName;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String receiptFooter;
  final String currencyCode;
  final String logoUrl;
  final double subtotal;
  final double discount;
  final double tax;
  final double taxRate;
  final double total;
  final double paid;
  final double change;
  final double creditAmount;
  final List<Map<String, dynamic>> cart;

  const _ReceiptCard({
    required this.saleNo,
    required this.paymentMethod,
    required this.customerName,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.receiptFooter,
    required this.currencyCode,
    required this.logoUrl,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.taxRate,
    required this.total,
    required this.paid,
    required this.change,
    required this.creditAmount,
    required this.cart,
  });

  String money(double value) => '$currencyCode ${value.toStringAsFixed(0)}';

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrintingProvider>();
    final widthMm = provider.paperWidthMm(PrinterRole.receipt);

    // Scale the card width based on paper size to give a "preview" feel
    double cardWidth;
    if (widthMm <= 44) {
      cardWidth = 240;
    } else if (widthMm <= 58) {
      cardWidth = 300;
    } else if (widthMm <= 70 || widthMm <= 72) {
      cardWidth = 350;
    } else {
      cardWidth = double.infinity;
    }

    return Center(
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  if (logoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Image.network(
                        logoUrl,
                        height: widthMm >= 70 ? 24 : 18,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  Text(
                    storeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widthMm >= 70 ? 20 : 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.tr('sales_receipt'),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: context.tr('sale_no'), value: saleNo),
            _InfoRow(label: context.tr('customer'), value: customerName),
            _InfoRow(label: context.tr('payment'), value: paymentMethod),
            const Divider(),

            ...cart.map((item) {
              final qty = _toDouble(item['qty']);
              final price = _toDouble(item['price']);
              final lineTotal = qty * price;
              final isWeighted = item['is_weighted'] == true;
              final unitName = item['unit_name']?.toString() ?? (isWeighted ? 'kg' : 'pcs');
              final qtyText = isWeighted ? qty.toStringAsFixed(3) : qty.toInt().toString();

              return _InfoRow(
                label: '${item['name']} ($qtyText $unitName)',
                value: money(lineTotal),
              );
            }),

            const Divider(),
            _InfoRow(label: context.tr('subtotal'), value: money(subtotal)),
            _InfoRow(label: context.tr('discount'), value: money(discount)),
            _InfoRow(label: '${context.tr('tax')} ${taxRate.toStringAsFixed(0)}%', value: money(tax)),
            _InfoRow(label:context.tr('total'), value: money(total), strong: true),
            _InfoRow(label: context.tr('paid'), value: money(paid)),
            if (paymentMethod == 'Cash')
              _InfoRow(label: context.tr('change'), value: money(change)),
            if (paymentMethod == 'Credit')
              _InfoRow(label: context.tr('credit'), value: money(creditAmount)),
            const Divider(),
            if (storeAddress.isNotEmpty)
              Center(
                child: Text(
                  storeAddress,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ),
            if (storePhone.isNotEmpty)
              Center(
                child: Text(
                  '${context.tr('phone')}: $storePhone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                receiptFooter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
                fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong
                  ? const Color(0xFF10B981)
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return BoxDecoration(
    color: theme.cardTheme.color ?? colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
    boxShadow: isDark ? [] : const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}
