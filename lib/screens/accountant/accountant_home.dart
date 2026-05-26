import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/ledger.dart';
import '../../models/user.dart';
import '../../services/pdf_service.dart';
import '../../widgets/common_widgets.dart';
import 'add_fee_screen.dart';

class AccountantHome extends StatefulWidget {
  const AccountantHome({
    super.key,
    required this.database,
    required this.user,
    required this.onLogout,
  });

  final AppDatabase database;
  final User user;
  final VoidCallback onLogout;

  @override
  State<AccountantHome> createState() => _AccountantHomeState();
}

class _AccountantHomeState extends State<AccountantHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<_AccountantData> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _future = _load();
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_AccountantData> _load() async {
    final payments = await widget.database.recentPayments();
    final ledgers = await widget.database.studentLedgers();
    final fees = await widget.database.allFees();
    return _AccountantData(payments: payments, ledgers: ledgers, fees: fees);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _showAddFee() async {
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

  Future<void> _editFee(FeeRow feeRow) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddFeeScreen(database: widget.database, existingFee: feeRow),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  Future<void> _deleteFee(FeeRow feeRow) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer ce frais ?'),
          content: Text(
            'Le frais "${feeRow.fee.title}" de ${feeRow.student.fullName} sera supprime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await widget.database.deleteFee(feeRow.fee.id);
    if (!mounted) return;
    _refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Frais supprime')));
  }

  Future<void> _exportTransactions(List<PaymentRow> rows) async {
    await PdfService.generateTransactionReport(rows, 'complet');
  }

  @override
  Widget build(BuildContext context) {
    final onFeeTab = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Comptable'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transactions', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Gestion des frais', icon: Icon(Icons.account_balance)),
          ],
        ),
        actions: [
          FutureBuilder<_AccountantData>(
            future: _future,
            builder: (context, snapshot) {
              final payments = snapshot.data?.payments ?? const <PaymentRow>[];
              return IconButton(
                tooltip: 'Rapport PDF',
                onPressed: payments.isEmpty
                    ? null
                    : () => _exportTransactions(payments),
                icon: const Icon(Icons.picture_as_pdf_outlined),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: FutureBuilder<_AccountantData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final totalPaid = data.ledgers.fold<double>(
            0,
            (s, l) => s + l.totalPaid,
          );

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SummaryCard(
                      title: 'Recettes Totales',
                      value: formatMoney(totalPaid),
                      icon: Icons.account_balance_wallet,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Dernieres transactions'),
                    if (data.payments.isEmpty)
                      const EmptyState(
                        icon: Icons.history,
                        title: 'Aucun paiement',
                        message: 'Les transactions recentes apparaitront ici.',
                      )
                    else
                      ...data.payments.map(
                        (payment) => _AccountantPaymentTile(row: payment),
                      ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionTitle(
                      title: 'Frais ajoutes',
                      trailing: '${data.fees.length} frais',
                    ),
                    if (data.fees.isEmpty)
                      const EmptyState(
                        icon: Icons.account_balance_outlined,
                        title: 'Aucun frais',
                        message: 'Les frais ajoutes apparaitront ici.',
                      )
                    else
                      ...data.fees.map(
                        (feeRow) => _FeeManagementTile(
                          row: feeRow,
                          onEdit: () => _editFee(feeRow),
                          onDelete: () => _deleteFee(feeRow),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: onFeeTab
          ? FloatingActionButton.extended(
              onPressed: _showAddFee,
              label: const Text('Nouveau frais'),
              icon: const Icon(Icons.add_card),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _AccountantData {
  const _AccountantData({
    required this.payments,
    required this.ledgers,
    required this.fees,
  });

  final List<PaymentRow> payments;
  final List<StudentLedger> ledgers;
  final List<FeeRow> fees;
}

class _AccountantPaymentTile extends StatelessWidget {
  const _AccountantPaymentTile({required this.row});

  final PaymentRow row;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          child: const Icon(Icons.payment, color: AppColors.success),
        ),
        title: Text(
          row.student.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${row.fee.title}\n${row.payment.method}\n${formatRelativeTime(row.payment.paidAt)}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(row.payment.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            Text(
              formatDate(row.payment.paidAt),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeManagementTile extends StatelessWidget {
  const _FeeManagementTile({
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  final FeeRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: row.fee.isPaid
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.warning.withValues(alpha: 0.1),
          child: Icon(
            row.fee.isPaid
                ? Icons.check_circle_outline
                : Icons.pending_outlined,
            color: row.fee.isPaid ? AppColors.success : AppColors.warning,
          ),
        ),
        title: Text(
          row.fee.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${row.student.fullName}\n${row.student.promotionLabel} - ${row.student.departmentLabel}\nEcheance: ${formatDate(row.fee.dueDate)}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }
}
