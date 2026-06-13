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
  String? _selectedNetwork = 'Orange';
  String? _transactionId;
  String? _normalizedPhone;
  String? _lastStatus;

  static const List<String> _networks = ['Orange', 'Vodacom', 'Airtel'];

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
        child: switch (_step) {
          1 => _buildStep1(),
          2 => _buildStep2(),
          _ => _buildStep3(),
        },
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
                  'Choisissez le reseau, saisissez le numero, puis attendez la confirmation avant de valider le paiement.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedNetwork,
          decoration: const InputDecoration(
            labelText: 'Reseau',
            prefixIcon: Icon(Icons.sim_card_outlined),
          ),
          items: _networks
              .map((network) => DropdownMenuItem(
                    value: network,
                    child: Text(network),
                  ))
              .toList(),
          onChanged: _isLoading
              ? null
              : (value) => setState(() => _selectedNetwork = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          enabled: !_isLoading,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Numero de telephone',
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
              : const Text('Lancer le paiement'),
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
        const Icon(Icons.hourglass_bottom, size: 80, color: AppColors.warning),
        const SizedBox(height: 16),
        const Text(
          'Paiement en attente',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Le paiement a ete transmis mais il n est pas encore confirme. Nous attendons la validation avant de l enregistrer comme paye.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        if (_transactionId != null)
          Text(
            'Reference provisoire: $_transactionId',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        if (_lastStatus != null) ...[
          const SizedBox(height: 8),
          Text(
            'Statut actuel: $_lastStatus',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _verifyPayment,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Verifier la confirmation'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Fermer'),
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
          'Paiement confirme',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Le paiement a ete valide et enregistre avec succes.',
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
    if (_selectedNetwork == null || _selectedNetwork!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez selectionner un reseau')),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numero de telephone valide')),
      );
      return;
    }

    final normalizedPhone = ShwaryService.normalizePhoneNumber(phone);
    debugPrint('[Shwary] Debut du paiement pour $normalizedPhone');

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paiement en cours...')));
    setState(() => _isLoading = true);

    try {
      final paymentApi = PaymentApiService();
      final result = await paymentApi.pay(
        amount: widget.fee.amount,
        phoneNumber: normalizedPhone,
      );

      debugPrint(
        '[Shwary] Resultat: success=${result.success}, status=${result.status}, transaction=${result.transactionId}, message=${result.message}',
      );

      if (!result.success) {
        throw Exception(
          result.message ?? 'Le paiement n a pas ete accepte par Shwary.',
        );
      }

      _normalizedPhone = normalizedPhone;
      _transactionId =
          result.transactionId ?? 'SHWARY-${DateTime.now().millisecondsSinceEpoch}';
      _lastStatus = result.status;

      if (ShwaryService.isSuccessfulStatus(result.status)) {
        await _confirmPayment(
          reference: _transactionId!,
          status: result.status,
        );
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _step = 3;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement valide et enregistre.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement en attente de confirmation.'),
        ),
      );
    } catch (e) {
      debugPrint('[Shwary] Erreur: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur Shwary detaillee: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _verifyPayment() async {
    if (_transactionId == null || _normalizedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune transaction a verifier')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final verification = await ShwaryService.verifyTransaction(
        _transactionId!,
      );
      _lastStatus = verification.status;

      if (!verification.success) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verification.message ??
                  'Le paiement est toujours en attente de confirmation.',
            ),
          ),
        );
        return;
      }

      await _confirmPayment(
        reference: _transactionId!,
        status: verification.status,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 3;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement confirme avec succes.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification impossible: $e')),
      );
    }
  }

  Future<void> _confirmPayment({
    required String reference,
    String? status,
  }) async {
    await widget.database.recordExternalPayment(
      widget.fee,
      network: _selectedNetwork!,
      method: 'Mobile Money',
      accountNumber: _normalizedPhone!,
      reference: reference,
      gateway: 'Shwary',
      status: status,
    );
  }
}
