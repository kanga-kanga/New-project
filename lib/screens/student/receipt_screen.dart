import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';
import '../../services/pdf_service.dart';

class ReceiptScreen extends StatelessWidget {
  final Payment payment;
  final User student;
  final String feeTitle;

  const ReceiptScreen({
    super.key,
    required this.payment,
    required this.student,
    required this.feeTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reçu de Paiement')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey.shade50],
                    ),
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/logo.png', height: 80),
                      const SizedBox(height: 16),
                      const Text(
                        'ISP / LUBUMBASHI',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'REÇU OFFICIEL',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.primary),
                      ),
                      const Divider(height: 40),
                      _buildRow('Étudiant', student.fullName),
                      _buildRow('Frais Payé', feeTitle, isHighlight: true),
                      _buildRow('Montant', formatMoney(payment.amount)),
                      _buildRow('Date', formatDate(payment.paidAt)),
                      _buildRow('Méthode', payment.method),
                      _buildRow('Référence', payment.reference),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified, color: AppColors.success),
                            SizedBox(width: 8),
                            Text(
                              'PAIEMENT VALIDÉ',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      PdfService.generateReceipt(payment, student, feeTitle);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger PDF'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      PdfService.generateReceipt(payment, student, feeTitle);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: isHighlight ? 16 : 14,
                color: isHighlight ? AppColors.primary : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
