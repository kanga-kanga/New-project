import 'dart:math';
import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../models/fee.dart';
import '../../widgets/common_widgets.dart';

class PaymentSimulationSheet extends StatefulWidget {
  final Fee fee;
  final AppDatabase database;

  const PaymentSimulationSheet({
    super.key,
    required this.fee,
    required this.database,
  });

  @override
  State<PaymentSimulationSheet> createState() => _PaymentSimulationSheetState();
}

class _PaymentSimulationSheetState extends State<PaymentSimulationSheet> {
  int _step = 1; // 1: Method/Number, 2: OTP, 3: Success
  String _method = 'Mobile Money';
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _generatedOtp;
  bool _isLoading = false;

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
        child: _step == 1
            ? _buildStep1()
            : _step == 2
                ? _buildStep2()
                : _buildStep3(),
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
        DropdownButtonFormField<String>(
          value: _method,
          decoration: const InputDecoration(labelText: 'Moyen de paiement'),
          items: ['Mobile Money', 'Carte Bancaire', 'Virement']
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _method = v!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: _method == 'Carte Bancaire' ? 'Numéro de carte' : 'Numéro de téléphone',
            prefixIcon: const Icon(Icons.phone_android),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _sendOtp,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Envoyer le code de confirmation'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text(
          'Vérification',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Un code de confirmation a été envoyé au ${_phoneController.text}.\n(Simulation: Votre code est $_generatedOtp)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
          maxLength: 6,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _verifyAndPay,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirmer le paiement'),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Modifier le numéro'),
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
          'Paiement Réussi !',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre paiement a été validé avec succès. Vous pouvez maintenant télécharger votre reçu.',
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

  void _sendOtp() async {
    if (_phoneController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un numéro valide')));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    _generatedOtp = (100000 + Random().nextInt(900000)).toString();
    
    setState(() {
      _isLoading = false;
      _step = 2;
    });
  }

  void _verifyAndPay() async {
    if (_otpController.text != _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code incorrect')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await widget.database.simulatePayment(
        widget.fee,
        method: _method,
        accountNumber: _phoneController.text,
      );
      
      setState(() {
        _isLoading = false;
        _step = 3;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}
