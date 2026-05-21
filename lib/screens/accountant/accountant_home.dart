import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../models/user.dart';
import '../../models/ledger.dart';
import '../../widgets/common_widgets.dart';
import 'add_fee_screen.dart';

class AccountantHome extends StatefulWidget {
  final AppDatabase database;
  final User user;
  final VoidCallback onLogout;

  const AccountantHome({
    super.key,
    required this.database,
    required this.user,
    required this.onLogout,
  });

  @override
  State<AccountantHome> createState() => _AccountantHomeState();
}

class _AccountantHomeState extends State<AccountantHome> {
  late Future<_AccountantData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AccountantData> _load() async {
    final payments = await widget.database.recentPayments();
    final ledgers = await widget.database.studentLedgers();
    return _AccountantData(payments: payments, ledgers: ledgers);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _showAddFee() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddFeeScreen(database: widget.database),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Comptable'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: FutureBuilder<_AccountantData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;

          final totalPaid = data.ledgers.fold<double>(0, (s, l) => s + l.totalPaid);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SummaryCard(
                  title: 'Recettes Totales',
                  value: formatMoney(totalPaid),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.success,
                ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Dernières Transactions'),
                if (data.payments.isEmpty)
                  const EmptyState(
                    icon: Icons.history,
                    title: 'Aucun paiement',
                    message: 'Les transactions récentes apparaîtront ici.',
                  )
                else
                  ...data.payments.map((p) => _AccountantPaymentTile(row: p)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFee,
        label: const Text('Nouveau Frais'),
        icon: const Icon(Icons.add_card),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AccountantData {
  final List<PaymentRow> payments;
  final List<StudentLedger> ledgers;
  _AccountantData({required this.payments, required this.ledgers});
}

class _AccountantPaymentTile extends StatelessWidget {
  final PaymentRow row;

  const _AccountantPaymentTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF0FDF4),
          child: Icon(Icons.payment, color: AppColors.success),
        ),
        title: Text(row.student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${row.fee.title}\n${row.payment.method}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(row.payment.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
            ),
            Text(formatDate(row.payment.paidAt), style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
