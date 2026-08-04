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

  Future<void> printReceipt(BuildContext context) async {
    final printingProvider = context.read<PrintingProvider>();
    final logoBytes = printingProvider.logoBytes;

    if (printingProvider.isConnected) {
      await _printToThermalPrinter(printingProvider, logoBytes);
    } else {
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
          // Drastically reduced for "Extra Small" look
          int targetWidth;
          if (width >= 80) {
            targetWidth = 140; 
          } else if (width >= 70) {
            targetWidth = 135;
          } else if (width >= 58) {
            targetWidth = 100; 
          } else {
            targetWidth = 60; 
          }

          final resizedImage = img.copyResize(image, width: targetWidth);
          bytes += generator.image(resizedImage);
          bytes += generator.feed(1);
        }
      } catch (e) {
        debugPrint('Error processing logo for thermal printer: $e');
      }
    }

    // Helper to add text or rows with simulated margins
    void addLine(String text, {PosStyles styles = const PosStyles()}) {
      // Simulate a small margin (approx 0.5 column) using spaces
      const String leftMargin = "  "; 
      const String rightMargin = "  ";
      if (isTiny) {
        bytes += generator.text(leftMargin + text + rightMargin, styles: styles);
      } else {
        int margin = width >= 70 ? 0 : 0;
        if (margin <= 0) {
          bytes += generator.text(leftMargin + text + rightMargin, styles: styles);
        } else {
          bytes += generator.row([
            PosColumn(text: '', width: margin),
            PosColumn(text: text, width: 12 - (margin * 2), styles: styles),
            PosColumn(text: '', width: margin),
          ]);
        }
      }
    }

    void addRow(List<PosColumn> columns) {
      // Simulate a small margin (approx 0.5 column) using spaces
      const String leftMargin = "  ";
      const String rightMargin = "  ";
      
      if (isTiny) {
        if (columns.isNotEmpty) {
           // Add left padding to first column
           columns[0] = PosColumn(
            text: leftMargin + columns[0].text,
            width: columns[0].width,
            styles: columns[0].styles,
          );
          // Add right padding to last column
          if (columns.length > 1) {
            columns[columns.length - 1] = PosColumn(
              text: columns[columns.length - 1].text + rightMargin,
              width: columns[columns.length - 1].width,
              styles: columns[columns.length - 1].styles,
            );
          }
        }
        bytes += generator.row(columns);
      } else {
        int margin = width >= 70 ? 0 : 0;
        if (margin <= 0) {
          if (columns.isNotEmpty) {
             columns[0] = PosColumn(
              text: leftMargin + columns[0].text,
              width: columns[0].width,
              styles: columns[0].styles,
            );
            if (columns.length > 1) {
              columns[columns.length - 1] = PosColumn(
                text: columns[columns.length - 1].text + rightMargin,
                width: columns[columns.length - 1].width,
                styles: columns[columns.length - 1].styles,
              );
            }
          }
          bytes += generator.row(columns);
        } else {
          int availableWidth = 12 - (margin * 2);

          // Adjust column widths to fit in available space
          int totalOriginalWidth = 0;
          for (var col in columns) {
            totalOriginalWidth += col.width;
          }

          List<PosColumn> adjustedColumns = [];
          adjustedColumns.add(PosColumn(text: '', width: margin));

          int currentSum = 0;
          for (int i = 0; i < columns.length; i++) {
            int newWidth =
                ((columns[i].width / totalOriginalWidth) * availableWidth)
                    .round();
            if (i == columns.length - 1) {
              newWidth = availableWidth - currentSum;
            }
            currentSum += newWidth;

            adjustedColumns.add(PosColumn(
              text: columns[i].text,
              width: newWidth,
              styles: columns[i].styles,
            ));
          }

          adjustedColumns.add(PosColumn(text: '', width: margin));
          bytes += generator.row(adjustedColumns);
        }
      }
    }

    // Header
    addLine(widget.storeName,
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: isTiny ? PosTextSize.size1 : PosTextSize.size2,
          width: isTiny ? PosTextSize.size1 : PosTextSize.size2,
        ));
    addLine('Sales Receipt', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);

    // Info
    addLine('Sale: ${widget.saleNo}');
    if (!isTiny) {
      addLine('Customer: ${widget.customerName}');
      addLine('Payment: ${widget.paymentMethod}');
    }
    addLine('Date: ${DateTime.now().toString().substring(0, 16)}');
    bytes += generator.hr();

    // Items
    for (var item in widget.cart) {
      final qty = _toDouble(item['qty']);
      final price = _toDouble(item['price']);
      final lineTotal = qty * price;
      final isWeighted = item['is_weighted'] == true;
      final unitName =
          item['unit_name']?.toString() ?? (isWeighted ? 'kg' : 'pcs');
      final qtyText =
          isWeighted ? qty.toStringAsFixed(3) : qty.toInt().toString();

      addLine(item['name'].toString(), styles: const PosStyles(bold: true));

      if (isTiny) {
        bytes += generator.text('$qtyText $unitName x ${money(price)}');
        bytes += generator.text(money(lineTotal),
            styles: const PosStyles(align: PosAlign.right));
      } else {
        addRow([
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
    void addSummaryRow(String label, double value, {bool bold = false}) {
      if (isTiny) {
        bytes += generator.text('$label: ${money(value)}',
            styles: PosStyles(align: PosAlign.right, bold: bold));
      } else {
        addRow([
          PosColumn(text: label, width: 7, styles: PosStyles(bold: bold)),
          PosColumn(
              text: money(value),
              width: 5,
              styles: PosStyles(align: PosAlign.right, bold: bold)),
        ]);
      }
    }

    addSummaryRow('Subtotal', widget.subtotal);
    addSummaryRow('Discount', widget.discount);
    addSummaryRow('Tax ${widget.taxRate.toStringAsFixed(0)}%', widget.tax);

    bytes += generator.hr();

    if (isTiny) {
      bytes += generator.text('TOTAL: ${money(widget.total)}',
          styles: const PosStyles(align: PosAlign.right, bold: true));
    } else {
      addRow([
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
    }

    bytes += generator.feed(1);
    addLine('Paid: ${money(widget.paid)}',
        styles: const PosStyles(align: PosAlign.right));

    if (widget.paymentMethod == 'Cash') {
      addLine('Change: ${money(widget.change)}',
          styles: const PosStyles(align: PosAlign.right));
    }

    bytes += generator.feed(1);
    if (widget.storeAddress.isNotEmpty) {
      addLine(widget.storeAddress,
          styles: const PosStyles(align: PosAlign.center));
    }
    if (widget.storePhone.isNotEmpty) {
      addLine('Phone: ${widget.storePhone}',
          styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.feed(1);
    addLine(widget.receiptFooter,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    final type = provider.connectionType == PrinterConnectionType.bluetooth
        ? PrinterType.bluetooth
        : PrinterType.usb;

    await provider.printerManager.send(type: type, bytes: bytes);
  }

  Future<void> sharePdfReceipt() async {
    final printingProvider = context.read<PrintingProvider>();
    final logoBytes = printingProvider.logoBytes;
    final pdfBytes = await _buildReceiptPdf(logoBytes).save();

    await Printing.sharePdf(bytes: pdfBytes, filename: '${widget.saleNo}-receipt.pdf');
  }

  pw.Document _buildReceiptPdf(Uint8List? logoBytes) {
    final pdf = pw.Document();
    final provider = context.read<PrintingProvider>();
    final widthMm = provider.paperWidthMm;
    final isTiny = widthMm < 44;

    PdfPageFormat format;
    if (widthMm == 30) {
      format = PdfPageFormat(30 * PdfPageFormat.mm, double.infinity, 
          marginLeft: 2 * PdfPageFormat.mm, marginRight: 2 * PdfPageFormat.mm, 
          marginTop: 2 * PdfPageFormat.mm, marginBottom: 2 * PdfPageFormat.mm);
    } else if (widthMm == 44) {
      format = PdfPageFormat(44 * PdfPageFormat.mm, double.infinity, 
          marginLeft: 4 * PdfPageFormat.mm, marginRight: 4 * PdfPageFormat.mm,
          marginTop: 2 * PdfPageFormat.mm, marginBottom: 2 * PdfPageFormat.mm);
    } else if (widthMm == 57) {
      format = PdfPageFormat.roll57.copyWith(
          marginLeft: 5 * PdfPageFormat.mm, marginRight: 5 * PdfPageFormat.mm);
    } else if (widthMm == 58) {
      format = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, 
          marginLeft: 6 * PdfPageFormat.mm, marginRight: 6 * PdfPageFormat.mm,
          marginTop: 2 * PdfPageFormat.mm, marginBottom: 2 * PdfPageFormat.mm);
    } else if (widthMm == 70 || widthMm == 72) {
      format = PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity, 
          marginLeft: 5 * PdfPageFormat.mm, marginRight: 5 * PdfPageFormat.mm,
          marginTop: 2 * PdfPageFormat.mm, marginBottom: 2 * PdfPageFormat.mm);
    } else {
      format = PdfPageFormat.roll80.copyWith(
          marginLeft: 5 * PdfPageFormat.mm, marginRight: 5 * PdfPageFormat.mm,
          marginTop: 2 * PdfPageFormat.mm, marginBottom: 2 * PdfPageFormat.mm);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          final double baseFontSize = widthMm >= 70 ? 10 : 9;
          final double fontSize = isTiny ? 7 : baseFontSize;
          final double headerSize = isTiny ? 10 : baseFontSize + 4;

          return pw.Center(
            child: pw.SizedBox(
              width: widthMm >= 70 ? 54 * PdfPageFormat.mm : 44 * PdfPageFormat.mm,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoBytes != null)
                    pw.Center(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 2),
                        width: isTiny ? 20 : (widthMm >= 70 ? 30 : 25),
                        height: isTiny ? 6 : (widthMm >= 70 ? 12 : 10),
                        child: pw.Image(
                          pw.MemoryImage(logoBytes),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  pw.Center(
                    child: pw.Text(
                      widget.storeName,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: headerSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'Sales Receipt',
                      style: pw.TextStyle(
                        fontSize: fontSize,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _pdfRow('Sale No', widget.saleNo, fontSize: fontSize),
                  if (!isTiny)
                    _pdfRow('Customer', widget.customerName, fontSize: fontSize),
                  _pdfRow('Date', DateTime.now().toString().substring(0, 16),
                      fontSize: fontSize),
                  pw.Divider(thickness: 0.5),
                  ...widget.cart.map((item) {
                    final name = item['name'].toString();
                    final qty = _toDouble(item['qty']);
                    final price = _toDouble(item['price']);
                    final lineTotal = qty * price;
                    final isWeighted = item['is_weighted'] == true;
                    final unitName = item['unit_name']?.toString() ??
                        (isWeighted ? 'kg' : 'pcs');
                    final qtyText = isWeighted
                        ? qty.toStringAsFixed(3)
                        : qty.toInt().toString();

                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(name,
                            style: pw.TextStyle(
                                fontSize: fontSize,
                                fontWeight: pw.FontWeight.bold)),
                        _pdfRow('$qtyText $unitName x ${money(price)}',
                            money(lineTotal),
                            fontSize: fontSize),
                        pw.SizedBox(height: 2),
                      ],
                    );
                  }),
                  pw.Divider(thickness: 0.5),
                  _pdfRow('Subtotal', money(widget.subtotal),
                      fontSize: fontSize),
                  _pdfRow('Discount', money(widget.discount),
                      fontSize: fontSize),
                  _pdfRow('Tax ${widget.taxRate.toStringAsFixed(0)}%',
                      money(widget.tax),
                      fontSize: fontSize),
                  pw.Divider(thickness: 0.5),
                  _pdfRow('Total', money(widget.total),
                      bold: true,
                      fontSize: isTiny ? fontSize : fontSize + 2),
                  _pdfRow('Paid', money(widget.paid), fontSize: fontSize),
                  if (widget.paymentMethod == 'Cash')
                    _pdfRow('Change', money(widget.change), fontSize: fontSize),
                  pw.SizedBox(height: 8),
                  if (widget.storeAddress.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        widget.storeAddress,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: fontSize - 1),
                      ),
                    ),
                  if (widget.storePhone.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        'Phone: ${widget.storePhone}',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: fontSize - 1),
                      ),
                    ),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.Text(
                      widget.receiptFooter,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          fontSize: fontSize - 1,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
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
    final widthMm = provider.paperWidthMm;
    
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
            _InfoRow(label: 'Subtotal', value: money(subtotal)),
            _InfoRow(label: 'Discount', value: money(discount)),
            _InfoRow(label: 'Tax ${taxRate.toStringAsFixed(0)}%', value: money(tax)),
            _InfoRow(label: 'Total', value: money(total), strong: true),
            _InfoRow(label: 'Paid', value: money(paid)),
            if (paymentMethod == 'Cash')
              _InfoRow(label: 'Change', value: money(change)),
            if (paymentMethod == 'Credit')
              _InfoRow(label: 'Credit', value: money(creditAmount)),
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
                  'Phone: $storePhone',
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
