import 'dart:math';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BarcodeUtils {
  static String generateRandomBarcode() {
    final random = Random();
    // Generate a 12-digit random number as a string
    return List.generate(12, (_) => random.nextInt(10).toString()).join();
  }

  static Future<void> printLabel({
    required String name,
    required String code,
    required String price,
  }) async {
    final pdf = pw.Document();
    final bc = Barcode.code128();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                width: 40 * PdfPageFormat.mm,
                height: 15 * PdfPageFormat.mm,
                child: pw.BarcodeWidget(
                  barcode: bc,
                  data: code,
                  drawText: true,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Price: $price',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
