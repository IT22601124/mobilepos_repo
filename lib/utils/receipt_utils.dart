import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:mpos/utils/app_localizations.dart';

class ReceiptData {
  final String saleNo;
  final String date;
  final String customerName;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double taxRate;
  final double total;
  final double paid;
  final double change;
  final double creditAmount;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String receiptFooter;
  final String currencyCode;
  final Uint8List? logoBytes;

  ReceiptData({
    required this.saleNo,
    required this.date,
    required this.customerName,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.taxRate,
    required this.total,
    required this.paid,
    required this.change,
    required this.creditAmount,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.receiptFooter,
    required this.currencyCode,
    this.logoBytes,
  });

  static ReceiptData sample(BuildContext context) {
    return ReceiptData(
      saleNo: 'POS-SAMPLE-001',
      date: DateTime.now().toString().substring(0, 16),
      customerName: 'Sample Customer',
      paymentMethod: 'Cash',
      items: [
        {'name': 'Item A', 'qty': 2.0, 'price': 500.0, 'unit_name': 'pcs'},
        {'name': 'Item B', 'qty': 1.5, 'price': 1200.0, 'unit_name': 'kg', 'is_weighted': true},
      ],
      subtotal: 2800,
      discount: 100,
      tax: 135,
      taxRate: 5,
      total: 2835,
      paid: 3000,
      change: 165,
      creditAmount: 0,
      storeName: 'Sample Store',
      storeAddress: '123 Main St, City',
      storePhone: '0112345678',
      receiptFooter: 'Thank you for shopping!',
      currencyCode: 'LKR',
    );
  }
}

class ReceiptUtils {
  static Future<List<int>> generateThermalBytes({
    required ReceiptData data,
    required PaperSize paperSize,
    required CapabilityProfile profile,
    required BuildContext context,
  }) async {
    final generator = Generator(paperSize, profile);
    final widthMm = paperSize == PaperSize.mm58 ? 58 : (paperSize == PaperSize.mm72 ? 72 : 80);
    final isTiny = widthMm < 44;
    
    List<int> bytes = [];

    // Logo
    if (data.logoBytes != null) {
      try {
        final img.Image? image = img.decodeImage(data.logoBytes!);
        if (image != null) {
          int targetWidth = widthMm >= 80 ? 140 : (widthMm >= 58 ? 100 : 60);
          final resizedImage = img.copyResize(image, width: targetWidth);
          bytes += generator.image(resizedImage);
          bytes += generator.feed(1);
        }
      } catch (e) {
        debugPrint('Error processing logo: $e');
      }
    }

    void addLine(String text, {PosStyles styles = const PosStyles()}) {
      bytes += generator.text(text, styles: styles);
    }

    void addRow(List<PosColumn> columns) {
      bytes += generator.row(columns);
    }

    String money(double value) => '${data.currencyCode} ${value.toStringAsFixed(0)}';

    // Header
    addLine(data.storeName,
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: isTiny ? PosTextSize.size1 : PosTextSize.size2,
          width: isTiny ? PosTextSize.size1 : PosTextSize.size2,
        ));
    addLine(context.tr('sales_receipt'), styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);

    // Info
    addLine('${context.tr('sale_no')}: ${data.saleNo}');
    addLine('${context.tr('customer')}: ${data.customerName}');
    addLine('${context.tr('date')}: ${data.date}');
    bytes += generator.hr();

    // Items
    for (var item in data.items) {
      final qty = (item['qty'] as num).toDouble();
      final price = (item['price'] as num).toDouble();
      final lineTotal = qty * price;
      final unit = item['unit_name']?.toString() ?? 'pcs';
      final qtyText = (item['is_weighted'] == true) ? qty.toStringAsFixed(3) : qty.toInt().toString();

      addLine(item['name'].toString(), styles: const PosStyles(bold: true));
      addRow([
        PosColumn(text: '$qtyText $unit x ${money(price)}', width: 8),
        PosColumn(text: money(lineTotal), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Summary
    void addSummaryRow(String label, double value, {bool bold = false}) {
      addRow([
        PosColumn(text: label, width: 8, styles: PosStyles(bold: bold)),
        PosColumn(text: money(value), width: 4, styles: PosStyles(align: PosAlign.right, bold: bold)),
      ]);
    }

    addSummaryRow(context.tr('subtotal'), data.subtotal);
    addSummaryRow(context.tr('discount'), data.discount);
    addSummaryRow('${context.tr('tax')} ${data.taxRate.toStringAsFixed(0)}%', data.tax);
    bytes += generator.hr();
    addSummaryRow(context.tr('total'), data.total, bold: true);
    addSummaryRow(context.tr('paid'), data.paid);
    if (data.paymentMethod == 'Cash') {
      addSummaryRow(context.tr('change'), data.change);
    }
    if (data.creditAmount > 0) {
      addSummaryRow(context.tr('credit'), data.creditAmount);
    }

    bytes += generator.feed(1);
    if (data.storeAddress.isNotEmpty) {
      addLine(data.storeAddress, styles: const PosStyles(align: PosAlign.center));
    }
    if (data.storePhone.isNotEmpty) {
      addLine('${context.tr('phone')}: ${data.storePhone}', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(1);
    addLine(data.receiptFooter, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  static pw.Document generatePdfReceipt({
    required ReceiptData data,
    required double widthMm,
    required BuildContext context,
  }) {
    final pdf = pw.Document();
    
    PdfPageFormat format = PdfPageFormat(widthMm * PdfPageFormat.mm, double.infinity,
        marginLeft: 5 * PdfPageFormat.mm, marginRight: 5 * PdfPageFormat.mm,
        marginTop: 5 * PdfPageFormat.mm, marginBottom: 5 * PdfPageFormat.mm);

    String money(double value) => '${data.currencyCode} ${value.toStringAsFixed(0)}';

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          final double fontSize = widthMm >= 70 ? 10 : 8;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (data.logoBytes != null)
                pw.Center(child: pw.Image(pw.MemoryImage(data.logoBytes!), width: 40)),
              pw.Center(child: pw.Text(data.storeName, style: pw.TextStyle(fontSize: fontSize + 4, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Sales Receipt', style: pw.TextStyle(fontSize: fontSize))),
              pw.SizedBox(height: 10),
              _pdfRow('Sale No', data.saleNo, fontSize),
              _pdfRow('Date', data.date, fontSize),
              _pdfRow('Customer', data.customerName, fontSize),
              pw.Divider(thickness: 0.5),
              ...data.items.map((item) {
                final qty = (item['qty'] as num).toDouble();
                final price = (item['price'] as num).toDouble();
                return _pdfRow('${item['name']} ($qty x ${money(price)})', money(qty * price), fontSize);
              }),
              pw.Divider(thickness: 0.5),
              _pdfRow('Subtotal', money(data.subtotal), fontSize),
              _pdfRow('Discount', money(data.discount), fontSize),
              _pdfRow('Total', money(data.total), fontSize, bold: true),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text(data.receiptFooter, style: pw.TextStyle(fontSize: fontSize - 1))),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _pdfRow(String label, String value, double fontSize, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }
}

class ReceiptPreviewWidget extends StatelessWidget {
  final ReceiptData data;
  const ReceiptPreviewWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String money(double value) => '${data.currencyCode} ${value.toStringAsFixed(0)}';

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.logoBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Image.memory(data.logoBytes!, height: 40, fit: pw.BoxFit.contain as BoxFit),
            ),
          Text(data.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
          if (data.storeAddress.isNotEmpty)
            Text(data.storeAddress, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          if (data.storePhone.isNotEmpty)
            Text('Phone: ${data.storePhone}', style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          const Text('SALES RECEIPT', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const Divider(),
          _row('No', data.saleNo),
          _row('Date', data.date),
          _row('Customer', data.customerName),
          const Divider(),
          ...data.items.map((item) {
             final qty = (item['qty'] as num).toDouble();
             final price = (item['price'] as num).toDouble();
             final isWeighted = item['is_weighted'] == true;
             final unit = item['unit_name']?.toString() ?? 'pcs';
             final qtyText = isWeighted ? qty.toStringAsFixed(3) : qty.toInt().toString();
             
             return _row('${item['name']} ($qtyText $unit x ${money(price)})', money(qty * price));
          }),
          const Divider(),
          _row('Subtotal', money(data.subtotal)),
          _row('Discount', money(data.discount)),
          _row('Tax (${data.taxRate.toStringAsFixed(0)}%)', money(data.tax)),
          const Divider(),
          _row('Total', money(data.total), bold: true),
          _row('Paid', money(data.paid)),
          if (data.paymentMethod == 'Cash')
            _row('Change', money(data.change)),
          if (data.creditAmount > 0)
            _row('Credit', money(data.creditAmount)),
          const SizedBox(height: 10),
          Text(data.receiptFooter, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : null),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
