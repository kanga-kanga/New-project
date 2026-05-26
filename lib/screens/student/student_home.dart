import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/fee.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';
import 'payment_simulation.dart';
import 'receipt_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({
    super.key,
    required this.database,
    required this.user,
    required this.onLogout,
  });

  final AppDatabase database;
  final User user;
  final VoidCallback onLogout;

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  late Future<_StudentData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentData> _load() async {
    final fees = await widget.database.feesForStudent(widget.user.id);
    final payments = await widget.database.paymentsForStudent(widget.user.id);
    return _StudentData(fees: fees, payments: payments);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Espace Etudiant', style: TextStyle(fontSize: 14)),
            Text(
              widget.user.fullName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: FutureBuilder<_StudentData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;

          final total = data.fees.fold<double>(0, (s, f) => s + f.amount);
          final paid = data.payments.fold<double>(0, (s, p) => s + p.amount);
          final percentage = total > 0 ? (paid / total) : 0.0;
          final pendingFees = data.fees.where((f) => !f.isPaid).toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProgressCard(percentage, paid, total),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(widget.user.promotionLabel),
                    subtitle: Text(
                      '${widget.user.departmentLabel} - Sexe ${widget.user.genderLabel}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Frais a payer'),
                if (pendingFees.isEmpty)
                  const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'En ordre',
                    message: 'Vous n avez aucun frais en attente.',
                  )
                else
                  ...pendingFees.map(
                    (fee) =>
                        _FeeTile(fee: fee, onTap: () => _startPayment(fee)),
                  ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Historique des paiements'),
                if (data.payments.isEmpty)
                  const EmptyState(
                    icon: Icons.history,
                    title: 'Aucun paiement',
                    message: 'Vos paiements apparaitront ici.',
                  )
                else
                  ...data.payments.map((payment) {
                    final feeTitle = data.fees
                        .firstWhere((fee) => fee.id == payment.feeId)
                        .title;
                    return _PaymentTile(
                      payment: payment,
                      student: widget.user,
                      feeTitle: feeTitle,
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(double percentage, double paid, double total) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progression de paiement',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatMoney(paid)} / ${formatMoney(total)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 8,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPayment(Fee fee) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          PaymentSimulationSheet(fee: fee, database: widget.database),
    );
    if (result == true) {
      _refresh();
    }
  }
}

class _StudentData {
  const _StudentData({required this.fees, required this.payments});

  final List<Fee> fees;
  final List<Payment> payments;
}

class _FeeTile extends StatelessWidget {
  const _FeeTile({required this.fee, required this.onTap});

  final Fee fee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          fee.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Echeance: ${formatDate(fee.dueDate)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(fee.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'Payer',
              style: TextStyle(color: AppColors.accent, fontSize: 12),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.student,
    required this.feeTitle,
  });

  final Payment payment;
  final User student;
  final String feeTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2FE),
          child: Icon(Icons.receipt, color: AppColors.accent),
        ),
        title: Text(payment.method),
        subtitle: Text(formatDate(payment.paidAt)),
        trailing: Text(
          formatMoney(payment.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(
                payment: payment,
                student: student,
                feeTitle: feeTitle,
              ),
            ),
          );
        },
      ),
    );
  }
}
