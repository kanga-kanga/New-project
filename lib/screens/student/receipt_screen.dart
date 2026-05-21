import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../models/fee.dart';
import '../../widgets/common_widgets.dart';

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
                      const Icon(Icons.school, size: 48, color: AppColors.primary),
                      const SizedBox(height: 16),
                      const Text(
                        'REÇU OFFICIEL',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const Divider(height: 40),
                      _buildRow('Étudiant', student.fullName),
                      _buildRow('Matricule', student.matricule ?? 'N/A'),
                      _buildRow('Frais', feeTitle),
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
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger PDF'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
