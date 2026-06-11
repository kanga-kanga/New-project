import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/fee.dart';
import '../../services/payment_api_service.dart';
import '../../services/shwary_service.dart';
import '../../widgets/common_widgets.dart';

class PaymentSimulationSheet extends StatefulWidget {
  const PaymentSimulationSheet({
    super.key,
    required this.fee,
    required this.database,
  });

  final Fee fee;
  final AppDatabase database;

  @override
  State<PaymentSimulationSheet> createState() => _PaymentSimulationSheetState();
}

class _PaymentSimulationSheetState extends State<PaymentSimulationSheet> {
  int _step = 1;
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _step == 1 ? _buildStep1() : _buildStep3(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Paiement en ligne',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Frais: ${widget.fee.title}\nMontant: ${formatMoney(widget.fee.amount)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.phone_android, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paiement Mobile Money uniquement. Aucun autre mode n’est proposé.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone Mobile Money',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _processPayment,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Payer maintenant'),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      key: const ValueKey(3),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 80, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'Paiement initié !',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre paiement a été transmis à Shwary et est en attente de validation.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Terminer'),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un numéro de téléphone valide'),
        ),
      );
      return;
    }

    final normalizedPhone = ShwaryService.normalizePhoneNumber(phone);
    debugPrint('[Shwary] Début du paiement pour $normalizedPhone');

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paiement en cours…')));
    setState(() => _isLoading = true);

    try {
      final paymentApi = PaymentApiService();
      final result = await paymentApi.pay(
        amount: widget.fee.amount,
        phoneNumber: normalizedPhone,
      );

      debugPrint(
        '[Shwary] Résultat: success=${result.success}, status=${result.status}, transaction=${result.transactionId}, message=${result.message}',
      );

      if (!result.success) {
        throw Exception(
          result.message ?? 'Le paiement n’a pas été accepté par Shwary.',
        );
      }

      await widget.database.recordExternalPayment(
        widget.fee,
        method: 'Mobile Money',
        accountNumber: normalizedPhone,
        reference:
            result.transactionId ??
            'SHWARY-${DateTime.now().millisecondsSinceEpoch}',
        gateway: 'Shwary',
        status: result.status,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement initié avec succès. Validation en cours.'),
        ),
      );
    } catch (e) {
      debugPrint('[Shwary] Erreur: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur Shwary détaillée: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}
