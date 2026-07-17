import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PosPaymentSuccessScreen extends StatelessWidget {
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

  String money(double value) => '$currencyCode ${value.toStringAsFixed(0)}';

  Future<void> printReceipt() async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => _buildReceiptPdf().save(),
    );
  }

  Future<void> sharePdfReceipt() async {
    final pdfBytes = await _buildReceiptPdf().save();

    await Printing.sharePdf(bytes: pdfBytes, filename: '$saleNo-receipt.pdf');
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
                    storeName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(child: pw.Text('Sales Receipt')),
                pw.SizedBox(height: 10),
                _pdfRow('Sale No', saleNo),
                _pdfRow('Customer', customerName),
                _pdfRow('Payment', paymentMethod),
                _pdfRow('Date', DateTime.now().toString().substring(0, 16)),
                pw.Divider(),

                ...cart.map((item) {
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
                _pdfRow('Subtotal', money(subtotal)),
                _pdfRow('Discount', money(discount)),
                _pdfRow('Tax 8%', money(tax)),
                pw.Divider(),
                _pdfRow('Total', money(total), bold: true),
                _pdfRow('Paid', money(paid)),
                if (paymentMethod == 'Cash') _pdfRow('Change', money(change)),
                if (paymentMethod == 'Credit')
                  _pdfRow('Credit', money(creditAmount)),
                pw.SizedBox(height: 14),
                pw.Center(child: pw.Text(receiptFooter)),
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
    return AppBackScope(
      fallbackRoute: '/pos_terminal',
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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

            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFEAFBF1),
              child: Icon(
                Icons.check_circle,
                color: Color(0xFF23C16B),
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Center(
              child: Text(
                saleNo,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _ReceiptCard(
              saleNo: saleNo,
              paymentMethod: paymentMethod,
              customerName: customerName,
              storeName: storeName,
              receiptFooter: receiptFooter,
              currencyCode: currencyCode,
              logoUrl: logoUrl,
              subtotal: subtotal,
              discount: discount,
              tax: tax,
              total: total,
              paid: paid,
              change: change,
              creditAmount: creditAmount,
              cart: cart,
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: printReceipt,
              icon: const Icon(Icons.print),
              label: const Text('Print Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23C16B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: sharePdfReceipt,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Save / Share PDF Receipt'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            const SizedBox(height: 10),

            TextButton.icon(
              onPressed: () => context.go('/pos_terminal'),
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Start New Sale'),
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

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Theme.of(context).dividerColor),
    boxShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}
