import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/payment.dart';
import '../models/ledger.dart';
import '../database/app_database.dart';

class PdfService {
  static Future<pw.ImageProvider> _getLogo() async {
    final bytes = await rootBundle.load('assets/logo.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  static String _formatMoney(double amount) {
    return NumberFormat.currency(
      symbol: 'CDF ',
      decimalDigits: 2,
      locale: 'fr_CD',
    ).format(amount);
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  static Future<void> generateReceipt(
    Payment payment,
    User student,
    String feeTitle,
  ) async {
    final doc = pw.Document();
    final logo = await _getLogo();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logo, height: 100),
              pw.SizedBox(height: 16),
              pw.Text(
                'ISP / LUBUMBASHI',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'REÇU OFFICIEL',
                style: pw.TextStyle(fontSize: 20, letterSpacing: 2),
              ),
              pw.Divider(height: 40),

              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfRow('Étudiant', student.fullName),
                    _buildPdfRow('Frais Payé', feeTitle, isHighlight: true),
                    _buildPdfRow('Montant', _formatMoney(payment.amount)),
                    _buildPdfRow('Date', _formatDate(payment.paidAt)),
                    _buildPdfRow('Méthode', payment.method),
                    _buildPdfRow('Référence', payment.reference),
                  ],
                ),
              ),

              pw.SizedBox(height: 60),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E8F5E9'), // Light green
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                  border: pw.Border.all(color: PdfColor.fromHex('#4CAF50')),
                ),
                child: pw.Text(
                  'PAIEMENT VALIDÉ',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#4CAF50'),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'recu_${student.fullName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildPdfRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 14),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: isHighlight ? 16 : 14,
              color: isHighlight ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> generateTransactionReport(
    List<PaymentRow> rows,
    String periodName,
  ) async {
    final doc = pw.Document();
    final logo = await _getLogo();

    final totalAmount = rows.fold<double>(
      0,
      (sum, row) => sum + row.payment.amount,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Row(
              children: [
                pw.Image(logo, height: 60),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ISP / LUBUMBASHI',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'RAPPORT DES TRANSACTIONS',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Période: $periodName',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Étudiant', 'Frais', 'Méthode', 'Montant'],
              data: rows
                  .map(
                    (r) => [
                      _formatDate(r.payment.paidAt),
                      r.student.fullName,
                      r.fee.title,
                      r.payment.method,
                      _formatMoney(r.payment.amount),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total: ${_formatMoney(totalAmount)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'transactions_$periodName.pdf',
    );
  }

  static Future<void> generateStudentSituationReport(
    List<StudentLedger> ledgers,
  ) async {
    final doc = pw.Document();
    final logo = await _getLogo();

    final totalAttendu = ledgers.fold<double>(0, (sum, l) => sum + l.totalFees);
    final totalPercu = ledgers.fold<double>(0, (sum, l) => sum + l.totalPaid);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Row(
              children: [
                pw.Image(logo, height: 60),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ISP / LUBUMBASHI',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'SITUATION GLOBALE DES ÉTUDIANTS',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Attendu: ${_formatMoney(totalAttendu)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Total Perçu: ${_formatMoney(totalPercu)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: [
                'Étudiant',
                'Niveau',
                'Attendu',
                'Perçu',
                'Reste',
                'Statut',
              ],
              data: ledgers
                  .map(
                    (l) => [
                      l.student.fullName,
                      l.student.level ?? 'N/A',
                      _formatMoney(l.totalFees),
                      _formatMoney(l.totalPaid),
                      _formatMoney(l.balance),
                      l.isInOrder ? 'En ordre' : 'Non en ordre',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'situation_etudiants.pdf',
    );
  }
}
