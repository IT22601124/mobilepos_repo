import 'package:mpos/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:mpos/provider/printing_provider.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:image/image.dart' as img;
import 'package:dio/dio.dart';

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
    if (printingProvider.autoPrint && printingProvider.isConnected) {
      printReceipt(context);
    }
  }

  String money(double value) => '${widget.currencyCode} ${value.toStringAsFixed(0)}';

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<Uint8List?> _fetchLogoBytes(String url) async {
    if (url.isEmpty) return null;
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      debugPrint('Error fetching logo: $e');
    }
    return null;
  }

  Future<void> printReceipt(BuildContext context) async {
    final printingProvider = context.read<PrintingProvider>();
    final logoBytes = await _fetchLogoBytes(widget.logoUrl);

    if (printingProvider.isConnected) {
      // Print directly to the thermal printer
      await _printToThermalPrinter(printingProvider, logoBytes);
    } else {
      // Fallback to system print dialog (PDF)
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _buildReceiptPdf(logoBytes).save(),
      );
    }
  }

  Future<void> _printToThermalPrinter(PrintingProvider provider, Uint8List? logoBytes) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(provider.paperSize, profile);
    final width = provider.paperWidthMm;
    final isTiny = width < 44;
    
    List<int> bytes = [];

    // Logo
    if (logoBytes != null) {
      try {
        final img.Image? image = img.decodeImage(logoBytes);
        if (image != null) {
          // Resize image to fit paper width
          // 80mm is usually 576 dots, 58mm is 384 dots
          int targetWidth = provider.paperSize == PaperSize.mm80 ? 400 : 200;
          if (isTiny) targetWidth = 150;
          
          final resizedImage = img.copyResize(image, width: targetWidth);
          bytes += generator.image(resizedImage);
          bytes += generator.feed(1);
        }
      } catch (e) {
        debugPrint('Error processing logo for thermal printer: $e');
      }
    }

    // Header
    bytes += generator.text(widget.storeName,
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: isTiny ? PosTextSize.size1 : PosTextSize.size2,
          width: isTiny ? PosTextSize.size1 : PosTextSize.size2,
        ));
    bytes += generator.text(context.tr('sales_receipt'),
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);

    // Info
    bytes += generator.text('${context.tr('sale_no')}: ${widget.saleNo}');
    if (!isTiny) {
      bytes += generator.text('${context.tr('customer')}: ${widget.customerName}');
      bytes += generator.text('${context.tr('payment')}: ${widget.paymentMethod}');
    }
    bytes += generator.text('${context.tr('date')}: ${DateTime.now().toString().substring(0, 16)}');
    bytes += generator.hr();

    // Items
    for (var item in widget.cart) {
      final qty = _toDouble(item['qty']);
      final price = _toDouble(item['price']);
      final lineTotal = qty * price;
      final isWeighted = item['is_weighted'] == true;
      final unitName = item['unit_name']?.toString() ?? (isWeighted ? 'kg' : 'pcs');
      final qtyText = isWeighted ? qty.toStringAsFixed(3) : qty.toInt().toString();

      bytes += generator.text(item['name'].toString(),
          styles: const PosStyles(bold: true));
      
      if (isTiny) {
        bytes += generator.text('$qtyText $unitName x ${money(price)}');
        bytes += generator.text(money(lineTotal), styles: const PosStyles(align: PosAlign.right));
      } else {
        bytes += generator.row([
          PosColumn(text: '$qtyText $unitName x ${money(price)}', width: 7),
          PosColumn(
              text: money(lineTotal),
              width: 5,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr();

    // Summary
    void addRow(String label, double value, {bool bold = false}) {
      if (isTiny) {
        bytes += generator.text('$label: ${money(value)}', styles: PosStyles(align: PosAlign.right, bold: bold));
      } else {
        bytes += generator.row([
          PosColumn(text: label, width: 7, styles: PosStyles(bold: bold)),
          PosColumn(
              text: money(value),
              width: 5,
              styles: PosStyles(align: PosAlign.right, bold: bold)),
        ]);
      }
    }

    addRow(context.tr('subtotal'), widget.subtotal);
    addRow(context.tr('discount'), widget.discount);
    addRow('${context.tr('tax')} ${widget.taxRate.toStringAsFixed(0)}%', widget.tax);
    
    bytes += generator.hr();
    
    if (isTiny) {
      bytes += generator.text('${context.tr('total_caps')}: ${money(widget.total)}', 
          styles: const PosStyles(align: PosAlign.right, bold: true));
    } else {
      bytes += generator.row([
        PosColumn(
            text: context.tr('total_caps'),
            width: 7,
            styles: const PosStyles(bold: true, height: PosTextSize.size2)),
        PosColumn(
            text: money(widget.total),
            width: 5,
            styles: const PosStyles(
                align: PosAlign.right, bold: true, height: PosTextSize.size2)),
      ]);
    }

    bytes += generator.feed(1);
    bytes += generator.text('${context.tr('paid')}: ${money(widget.paid)}',
        styles: const PosStyles(align: PosAlign.right));
    
    if (widget.paymentMethod == 'Cash') {
      bytes += generator.text('${context.tr('change')}: ${money(widget.change)}',
          styles: const PosStyles(align: PosAlign.right));
    }

    bytes += generator.feed(1);
    if (widget.storeAddress.isNotEmpty) {
      bytes += generator.text(widget.storeAddress,
          styles: const PosStyles(align: PosAlign.center));
    }
    if (widget.storePhone.isNotEmpty) {
      bytes += generator.text('${context.tr('phone')}: ${widget.storePhone}',
          styles: const PosStyles(align: PosAlign.center));
    }
    
    bytes += generator.feed(1);
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
    final logoBytes = await _fetchLogoBytes(widget.logoUrl);
    final pdfBytes = await _buildReceiptPdf(logoBytes).save();

    await Printing.sharePdf(bytes: pdfBytes, filename: '${widget.saleNo}-receipt.pdf');
  }

  pw.Document _buildReceiptPdf(Uint8List? logoBytes) {
    final pdf = pw.Document();
    final provider = context.read<PrintingProvider>();
    final widthMm = provider.paperWidthMm;
    final isTiny = widthMm < 44;

    final String trReceipt = context.tr('sales_receipt');
    final String trSaleNo = context.tr('sale_no');
    final String trCustomer = context.tr('customer');
    final String trDate = context.tr('date');
    final String trSubtotal = context.tr('subtotal');
    final String trDiscount = context.tr('discount');
    final String trTax = context.tr('tax');
    final String trTotal = context.tr('total');
    final String trPaid = context.tr('paid');
    final String trChange = context.tr('change');
    final String trPhone = context.tr('phone');

    PdfPageFormat format;
    if (widthMm == 30) {
      format = PdfPageFormat(30 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm);
    } else if (widthMm == 44) {
      format = PdfPageFormat(44 * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm);
    } else if (widthMm == 57) {
      format = PdfPageFormat.roll57;
    } else if (widthMm == 58) {
      format = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);
    } else if (widthMm == 72) {
      format = PdfPageFormat(72 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm);
    } else {
      format = PdfPageFormat.roll80;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          final double fontSize = isTiny ? 7 : 9;
          final double headerSize = isTiny ? 10 : 14;

          return pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoBytes != null)
                  pw.Center(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 5),
                      height: isTiny ? 30 : 50,
                      child: pw.Image(pw.MemoryImage(logoBytes)),
                    ),
                  ),
                pw.Center(
                  child: pw.Text(
                    widget.storeName,
                    style: pw.TextStyle(
                      fontSize: headerSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(child: pw.Text(trReceipt, style: pw.TextStyle(fontSize: fontSize))),
                pw.SizedBox(height: 6),
                _pdfRow(trSaleNo, widget.saleNo, fontSize: fontSize),
                if (!isTiny) _pdfRow(trCustomer, widget.customerName, fontSize: fontSize),
                _pdfRow(trDate, DateTime.now().toString().substring(0, 16), fontSize: fontSize),
                pw.Divider(thickness: 0.5),

                ...widget.cart.map((item) {
                  final name = item['name'].toString();
                  final qty = _toDouble(item['qty']);
                  final price = _toDouble(item['price']);
                  final lineTotal = qty * price;
                  final isWeighted = item['is_weighted'] == true;
                  final unitName = item['unit_name']?.toString() ?? (isWeighted ? 'kg' : 'pcs');
                  final qtyText = isWeighted ? qty.toStringAsFixed(3) : qty.toInt().toString();

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
                      _pdfRow('$qtyText $unitName x ${money(price)}', money(lineTotal), fontSize: fontSize),
                      pw.SizedBox(height: 2),
                    ],
                  );
                }),

                pw.Divider(thickness: 0.5),
                _pdfRow(trSubtotal, money(widget.subtotal), fontSize: fontSize),
                _pdfRow(trDiscount, money(widget.discount), fontSize: fontSize),
                _pdfRow('$trTax ${widget.taxRate.toStringAsFixed(0)}%', money(widget.tax), fontSize: fontSize),
                pw.Divider(thickness: 0.5),
                _pdfRow(trTotal, money(widget.total), bold: true, fontSize: isTiny ? fontSize : fontSize + 2),
                _pdfRow(trPaid, money(widget.paid), fontSize: fontSize),
                if (widget.paymentMethod == 'Cash') _pdfRow(trChange, money(widget.change), fontSize: fontSize),
                pw.SizedBox(height: 8),
                if (widget.storeAddress.isNotEmpty)
                  pw.Center(child: pw.Text(widget.storeAddress, style: pw.TextStyle(fontSize: fontSize - 1))),
                if (widget.storePhone.isNotEmpty)
                  pw.Center(child: pw.Text('$trPhone: ${widget.storePhone}', style: pw.TextStyle(fontSize: fontSize - 1))),
                pw.SizedBox(height: 4),
                pw.Center(child: pw.Text(widget.receiptFooter, style: pw.TextStyle(fontSize: fontSize - 1))),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false, double fontSize = 9}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
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
          _InfoRow(label: context.tr('total'), value: money(total), strong: true),
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
