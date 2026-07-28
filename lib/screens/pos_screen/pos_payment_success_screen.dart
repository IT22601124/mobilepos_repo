import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/provider/printing_provider.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

class PosPaymentSuccessScreen extends StatefulWidget {
  final String saleNo;
  final String paymentMethod;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paid;
  final double change;
  final double creditAmount;
  final String customerName;
  final List<Map<String, dynamic>> cart;
  final String storeName;
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
    required this.total,
    required this.paid,
    required this.change,
    required this.creditAmount,
    required this.customerName,
    required this.cart,
    required this.storeName,
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
    if (printingProvider.autoPrint && printingProvider.isConnected) {
      printReceipt(context);
    }
  }

  String money(double value) => '${widget.currencyCode} ${value.toStringAsFixed(0)}';

  Future<void> printReceipt(BuildContext context) async {
    final printingProvider = context.read<PrintingProvider>();

    if (printingProvider.isConnected) {
      // Print directly to the thermal printer
      await _printToThermalPrinter(printingProvider);
    } else {
      // Fallback to system print dialog (PDF)
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _buildReceiptPdf().save(),
      );
    }
  }

  Future<void> _printToThermalPrinter(PrintingProvider provider) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(provider.paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(widget.storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    bytes += generator.text('Sales Receipt',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);

    // Info
    bytes += generator.text('Sale No: ${widget.saleNo}');
    bytes += generator.text('Customer: ${widget.customerName}');
    bytes += generator.text('Payment: ${widget.paymentMethod}');
    bytes += generator.text('Date: ${DateTime.now().toString().substring(0, 16)}');
    bytes += generator.hr();

    // Items
    for (var item in widget.cart) {
      final qty = item['qty'] as int;
      final price = item['price'] as double;
      final lineTotal = qty * price;

      bytes += generator.text(item['name'].toString(),
          styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(text: '$qty x ${money(price)}', width: 7),
        PosColumn(
            text: money(lineTotal),
            width: 5,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Summary
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 7),
      PosColumn(
          text: money(widget.subtotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Discount', width: 7),
      PosColumn(
          text: money(widget.discount),
          width: 5,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tax', width: 7),
      PosColumn(
          text: money(widget.tax),
          width: 5,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    bytes += generator.hr();
    
    bytes += generator.row([
      PosColumn(
          text: 'TOTAL',
          width: 7,
          styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
          text: money(widget.total),
          width: 5,
          styles: const PosStyles(
              align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);

    bytes += generator.feed(1);
    bytes += generator.text('Paid: ${money(widget.paid)}',
        styles: const PosStyles(align: PosAlign.right));
    
    if (widget.paymentMethod == 'Cash') {
      bytes += generator.text('Change: ${money(widget.change)}',
          styles: const PosStyles(align: PosAlign.right));
    }
    
    if (widget.paymentMethod == 'Credit') {
      bytes += generator.text('Credit: ${money(widget.creditAmount)}',
          styles: const PosStyles(align: PosAlign.right));
    }

    bytes += generator.feed(2);
    bytes += generator.text(widget.receiptFooter,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    final type = provider.connectionType == PrinterConnectionType.bluetooth
        ? PrinterType.bluetooth
        : PrinterType.usb;

    await provider.printerManager.send(type: type, bytes: bytes);
  }

  Future<void> sharePdfReceipt() async {
    final pdfBytes = await _buildReceiptPdf().save();

    await Printing.sharePdf(bytes: pdfBytes, filename: '${widget.saleNo}-receipt.pdf');
  }

  pw.Document _buildReceiptPdf() {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    widget.storeName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(child: pw.Text('Sales Receipt')),
                pw.SizedBox(height: 10),
                _pdfRow('Sale No', widget.saleNo),
                _pdfRow('Customer', widget.customerName),
                _pdfRow('Payment', widget.paymentMethod),
                _pdfRow('Date', DateTime.now().toString().substring(0, 16)),
                pw.Divider(),

                ...widget.cart.map((item) {
                  final name = item['name'].toString();
                  final qty = item['qty'] as int;
                  final price = item['price'] as double;
                  final lineTotal = qty * price;

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name),
                      _pdfRow('$qty x ${money(price)}', money(lineTotal)),
                      pw.SizedBox(height: 4),
                    ],
                  );
                }),

                pw.Divider(),
                _pdfRow('Subtotal', money(widget.subtotal)),
                _pdfRow('Discount', money(widget.discount)),
                _pdfRow('Tax 8%', money(widget.tax)),
                pw.Divider(),
                _pdfRow('Total', money(widget.total), bold: true),
                _pdfRow('Paid', money(widget.paid)),
                if (widget.paymentMethod == 'Cash') _pdfRow('Change', money(widget.change)),
                if (widget.paymentMethod == 'Credit')
                  _pdfRow('Credit', money(widget.creditAmount)),
                pw.SizedBox(height: 14),
                pw.Center(child: pw.Text(widget.receiptFooter)),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
        ),
        pw.Text(
          value,
          style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
        ),
      ],
    );
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
                'Payment Successful',
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
              receiptFooter: widget.receiptFooter,
              currencyCode: widget.currencyCode,
              logoUrl: widget.logoUrl,
              subtotal: widget.subtotal,
              discount: widget.discount,
              tax: widget.tax,
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
                    label: const Text('Share'),
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
                    label: const Text('Download'),
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
              label: const Text('Start New Sale'),
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
  final String receiptFooter;
  final String currencyCode;
  final String logoUrl;
  final double subtotal;
  final double discount;
  final double tax;
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
    required this.receiptFooter,
    required this.currencyCode,
    required this.logoUrl,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    required this.creditAmount,
    required this.cart,
  });

  String money(double value) => '$currencyCode ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      height: 48,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                Text(
                  storeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Sales Receipt',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Sale No', value: saleNo),
          _InfoRow(label: 'Customer', value: customerName),
          _InfoRow(label: 'Payment', value: paymentMethod),
          const Divider(),

          ...cart.map((item) {
            final qty = item['qty'] as int;
            final price = item['price'] as double;
            final lineTotal = qty * price;

            return _InfoRow(
              label: '${item['name']} x $qty',
              value: money(lineTotal),
            );
          }),

          const Divider(),
          _InfoRow(label: 'Subtotal', value: money(subtotal)),
          _InfoRow(label: 'Discount', value: money(discount)),
          _InfoRow(label: 'Tax 8%', value: money(tax)),
          _InfoRow(label: 'Total', value: money(total), strong: true),
          _InfoRow(label: 'Paid', value: money(paid)),
          if (paymentMethod == 'Cash')
            _InfoRow(label: 'Change', value: money(change)),
          if (paymentMethod == 'Credit')
            _InfoRow(label: 'Credit', value: money(creditAmount)),
          const Divider(),
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
