import 'package:pdf/pdf.dart';
// Notice the 'as pw' alias! This prevents our PDF widgets from colliding with Flutter widgets.
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';

class PdfService {
  static Future<void> generateAndPrintInvoice(InvoiceModel invoice) async {
    // 1. Create a new PDF Document
    final pdf = pw.Document();

    // 2. Add a page to the document
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // 3. Build the PDF UI using 'pw.' widgets!
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'FINLEDGER',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 30),

                // Client Details
                pw.Text(
                  'Billed To:',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                ),
                pw.Text(
                  invoice.clientName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 30),

                // Invoice Data Table
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      _buildPdfRow('Invoice ID:', invoice.id),
                      pw.Divider(),
                      _buildPdfRow('Status:', invoice.status),
                      pw.Divider(),
                      _buildPdfRow(
                        'Due Date:',
                        '${invoice.dueDate.month}/${invoice.dueDate.day}/${invoice.dueDate.year}',
                      ),
                      pw.Divider(),
                      _buildPdfRow(
                        'Total Amount:',
                        'Rs.${invoice.amount.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 4. This opens the native iOS/Android print & share dialog!
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.clientName.replaceAll(' ', '_')}.pdf',
    );
  }

  // A private helper method just for our PDF UI
  static pw.Widget _buildPdfRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
