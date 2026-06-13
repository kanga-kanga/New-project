import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/department.dart';
import '../../models/ledger.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';
import '../admin/add_student_screen.dart';
import '../accountant/add_fee_screen.dart';

class BudgetAdminHome extends StatefulWidget {
  const BudgetAdminHome({
    super.key,
    required this.database,
    required this.user,
    required this.onLogout,
  });

  final AppDatabase database;
  final User user;
  final VoidCallback onLogout;

  @override
  State<BudgetAdminHome> createState() => _BudgetAdminHomeState();
}

class _BudgetAdminHomeState extends State<BudgetAdminHome> {
  late Future<_BudgetAdminData> _future;
  final _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _departmentController.dispose();
    super.dispose();
  }

  Future<_BudgetAdminData> _load() async {
    final students = await widget.database.students();
    final ledgers = await widget.database.studentLedgers();
    final departments = await widget.database.departments();
    final fees = await widget.database.allFees();
    final payments = await widget.database.recentPayments();
    final promotions = await widget.database.promotions();
    return _BudgetAdminData(
      students: students,
      ledgers: ledgers,
      departments: departments,
      fees: fees,
      payments: payments,
      promotions: promotions,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _showAddStudent(List<Department> departments) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentScreen(
          database: widget.database,
          departments: departments,
        ),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  Future<void> _showDepartmentDialog() async {
    _departmentController.clear();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nouveau departement'),
          content: TextField(
            controller: _departmentController,
            decoration: const InputDecoration(labelText: 'Nom du departement'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final value = _departmentController.text.trim();
                if (value.isEmpty) {
                  return;
                }
                try {
                  await widget.database.createDepartment(value);
                  if (!mounted) return;
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  _refresh();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Departement ajoute')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editFee(FeeRow row) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddFeeScreen(database: widget.database, existingFee: row),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  Future<void> _deleteFee(FeeRow row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer ce frais ?'),
          content: Text(
            'Le frais "${row.fee.title}" de ${row.student.fullName} sera supprime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await widget.database.deleteFee(row.fee.id);
    if (!mounted) return;
    _refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Frais supprime')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Espace Budget', style: TextStyle(fontSize: 14)),
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
      body: FutureBuilder<_BudgetAdminData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final totalDue = data.ledgers.fold<double>(
            0,
            (sum, item) => sum + item.totalFees,
          );
          final totalPaid = data.ledgers.fold<double>(
            0,
            (sum, item) => sum + item.totalPaid,
          );
          final inOrderCount = data.ledgers.where((ledger) => ledger.isInOrder).length;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBrandCard(),
                const SizedBox(height: 16),
                _buildStatsRow(totalDue, totalPaid, inOrderCount, data.ledgers.length),
                const SizedBox(height: 24),
                _buildDepartmentSection(data.departments),
                const SizedBox(height: 24),
                SectionTitle(
                  title: 'Tableaux par promotion',
                  trailing: '${data.promotions.length} promotions',
                ),
                if (data.promotions.isEmpty)
                  const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'Aucune promotion',
                    message: 'Les promotions apparaitront ici une fois les etudiants crees.',
                  )
                else
                  ...data.promotions.map(
                    (promotion) => _PromotionLedgerCard(
                      promotion: promotion,
                      ledgers: data.ledgers
                          .where((ledger) => ledger.student.level == promotion)
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                SectionTitle(
                  title: 'Paiements recents',
                  trailing: '${data.payments.length} mouvements',
                ),
                if (data.payments.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Aucun paiement',
                    message: 'Les paiements apparaissent ici avec leur motif et l heure exacte.',
                  )
                else
                  _RecentPaymentsTable(rows: data.payments),
                const SizedBox(height: 24),
                SectionTitle(
                  title: 'Frais modifiables',
                  trailing: '${data.fees.length} lignes',
                ),
                if (data.fees.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'Aucun frais',
                    message: 'Créez un frais pour le regrouper par promotion et par etudiant.',
                  )
                else
                  ...data.fees.map(
                    (row) => _FeeManagementTile(
                      row: row,
                      onEdit: () => _editFee(row),
                      onDelete: () => _deleteFee(row),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<_BudgetAdminData>(
        future: _future,
        builder: (context, snapshot) {
          return FloatingActionButton.extended(
            onPressed: snapshot.hasData
                ? () => _showAddStudent(snapshot.data!.departments)
                : null,
            label: const Text('Nouvel etudiant'),
            icon: const Icon(Icons.person_add),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildBrandCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset('assets/logo.png', width: 48, height: 48),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direction budget',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tableaux de suivi des frais, departements, filieres et promotions par etudiant.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    double totalDue,
    double totalPaid,
    int inOrderCount,
    int totalStudents,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 170,
          child: SummaryCard(
            title: 'Total Attendu',
            value: formatMoney(totalDue),
            icon: Icons.account_balance,
            color: AppColors.primary,
          ),
        ),
        SizedBox(
          width: 170,
          child: SummaryCard(
            title: 'Total Percu',
            value: formatMoney(totalPaid),
            icon: Icons.payments,
            color: AppColors.success,
          ),
        ),
        SizedBox(
          width: 170,
          child: SummaryCard(
            title: 'En ordre',
            value: '$inOrderCount / $totalStudents',
            icon: Icons.verified_outlined,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSection(List<Department> departments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Departements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showDepartmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (departments.isEmpty)
              const Text('Aucun departement cree pour le moment.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: departments
                    .map((department) => Chip(label: Text(department.name)))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAdminData {
  const _BudgetAdminData({
    required this.students,
    required this.ledgers,
    required this.departments,
    required this.fees,
    required this.payments,
    required this.promotions,
  });

  final List<User> students;
  final List<StudentLedger> ledgers;
  final List<Department> departments;
  final List<FeeRow> fees;
  final List<PaymentRow> payments;
  final List<String> promotions;
}

class _PromotionLedgerCard extends StatelessWidget {
  const _PromotionLedgerCard({
    required this.promotion,
    required this.ledgers,
  });

  final String promotion;
  final List<StudentLedger> ledgers;

  @override
  Widget build(BuildContext context) {
    final inOrder = ledgers.where((ledger) => ledger.isInOrder).length;
    final total = ledgers.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    promotion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  '$inOrder / $total en ordre',
                  style: TextStyle(
                    color: inOrder == total ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Etudiant')),
                  DataColumn(label: Text('Departement')),
                  DataColumn(label: Text('Filiere')),
                  DataColumn(label: Text('Attendu')),
                  DataColumn(label: Text('Paye')),
                  DataColumn(label: Text('Reste')),
                  DataColumn(label: Text('Statut')),
                ],
                rows: ledgers.map((ledger) {
                  final inOrder = ledger.isInOrder;
                  final bg = inOrder
                      ? AppColors.success.withValues(alpha: 0.08)
                      : AppColors.error.withValues(alpha: 0.08);
                  return DataRow(
                    color: MaterialStatePropertyAll(bg),
                    cells: [
                      DataCell(Text(ledger.student.fullName)),
                      DataCell(Text(ledger.student.departmentLabel)),
                      DataCell(Text(ledger.student.filiereLabel)),
                      DataCell(Text(formatMoney(ledger.totalFees))),
                      DataCell(Text(formatMoney(ledger.totalPaid))),
                      DataCell(Text(formatMoney(ledger.balance))),
                      DataCell(
                        Text(
                          inOrder ? 'En ordre' : 'Non en ordre',
                          style: TextStyle(
                            color: inOrder ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPaymentsTable extends StatelessWidget {
  const _RecentPaymentsTable({required this.rows});

  final List<PaymentRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Etudiant')),
              DataColumn(label: Text('Departement')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Filiere')),
              DataColumn(label: Text('Motif')),
              DataColumn(label: Text('Methode')),
              DataColumn(label: Text('Montant')),
              DataColumn(label: Text('Date/heure')),
            ],
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: [
                      DataCell(Text(row.student.fullName)),
                      DataCell(Text(row.student.departmentLabel)),
                      DataCell(Text(row.student.promotionLabel)),
                      DataCell(Text(row.student.filiereLabel)),
                      DataCell(Text(row.fee.title)),
                      DataCell(Text(row.payment.method)),
                      DataCell(Text(formatMoney(row.payment.amount))),
                      DataCell(Text(formatDateTime(row.payment.paidAt))),
                    ],
                  ),
                )
                .toList(),
          ),
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
            row.fee.isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
            color: row.fee.isPaid ? AppColors.success : AppColors.warning,
          ),
        ),
        title: Text(
          row.fee.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${row.student.fullName}\n${row.student.departmentLabel} - ${row.student.promotionLabel} - ${row.student.filiereLabel}\nEcheance: ${formatDate(row.fee.dueDate)}',
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
