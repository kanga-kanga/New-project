import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/department.dart';
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
  late Future<_TreasuryData> _future;
  final _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _future = _load();
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<_TreasuryData> _load() async {
    final payments = await widget.database.recentPayments();
    final ledgers = await widget.database.studentLedgers();
    final fees = await widget.database.allFees();
    final departments = await widget.database.departments();
    final promotions = await widget.database.promotions();
    final students = await widget.database.students();
    return _TreasuryData(
      payments: payments,
      ledgers: ledgers,
      fees: fees,
      departments: departments,
      promotions: promotions,
      students: students,
    );
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer ce frais ?'),
          content: Text(
            'Le frais "${feeRow.fee.title}" de ${feeRow.student.fullName} sera supprime.',
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

    await widget.database.deleteFee(feeRow.fee.id);
    if (!mounted) return;
    _refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Frais supprime')));
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

  @override
  Widget build(BuildContext context) {
    final onFeeTab = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Espace Tresorerie', style: TextStyle(fontSize: 14)),
            Text(
              widget.user.fullName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Paiements', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Frais', icon: Icon(Icons.account_balance)),
            Tab(text: 'Departements', icon: Icon(Icons.account_tree_outlined)),
          ],
        ),
        actions: [
          FutureBuilder<_TreasuryData>(
            future: _future,
            builder: (context, snapshot) {
              final payments = snapshot.data?.payments ?? const <PaymentRow>[];
              return IconButton(
                tooltip: 'Export PDF',
                onPressed: payments.isEmpty
                    ? null
                    : () => PdfService.generateTransactionReport(
                        payments,
                        'transactions recents',
                      ),
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
      body: FutureBuilder<_TreasuryData>(
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
          final totalDue = data.ledgers.fold<double>(
            0,
            (s, l) => s + l.totalFees,
          );

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 160,
                          child: SummaryCard(
                            title: 'Recettes',
                            value: formatMoney(totalPaid),
                            icon: Icons.payments,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: SummaryCard(
                            title: 'Attendu',
                            value: formatMoney(totalDue),
                            icon: Icons.account_balance,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: SummaryCard(
                            title: 'Etudiants',
                            value: '${data.students.length}',
                            icon: Icons.people_alt_outlined,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SectionTitle(
                      title: 'Paiements par promotion',
                      trailing: '${data.promotions.length} promotions',
                    ),
                    if (data.promotions.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long,
                        title: 'Aucun paiement',
                        message: 'Les paiements seront affiches ici par promotion.',
                      )
                    else
                      ...data.promotions.map(
                        (promotion) => _PromotionPaymentCard(
                          promotion: promotion,
                          rows: data.payments
                              .where((row) => row.student.level == promotion)
                              .toList(),
                        ),
                      ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionTitle(
                      title: 'Frais par promotion et par etudiant',
                      trailing: '${data.fees.length} lignes',
                    ),
                    if (data.fees.isEmpty)
                      const EmptyState(
                        icon: Icons.account_balance_outlined,
                        title: 'Aucun frais',
                        message: 'Créez les frais ici pour les regrouper par promotion.',
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
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.logo_dev_outlined),
                        title: const Text('Departements et promotions'),
                        subtitle: const Text(
                          'Les departements sont ajoutees ici et les promotions sont affichees automatiquement depuis les etudiants inscrits.',
                        ),
                        trailing: FilledButton.icon(
                          onPressed: _showDepartmentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter departement'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionTitle(
                      title: 'Departements',
                      trailing: '${data.departments.length} departements',
                    ),
                    if (data.departments.isEmpty)
                      const EmptyState(
                        icon: Icons.account_tree_outlined,
                        title: 'Aucun departement',
                        message: 'Ajoutez un departement pour le voir dans les tableaux de paiement.',
                      )
                    else
                      _DepartmentTable(departments: data.departments),
                    const SizedBox(height: 24),
                    SectionTitle(
                      title: 'Promotions',
                      trailing: '${data.promotions.length} promotions',
                    ),
                    if (data.promotions.isEmpty)
                      const EmptyState(
                        icon: Icons.school_outlined,
                        title: 'Aucune promotion',
                        message: 'Les promotions apparaissent automatiquement selon les etudiants.',
                      )
                    else
                      _PromotionTable(
                        promotions: data.promotions,
                        ledgers: data.ledgers,
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

  Widget _buildHeroCard() {
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
                    'Direction de la trésorerie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Suivi des frais, des paiements et des filières par promotion.',
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
}

class _TreasuryData {
  const _TreasuryData({
    required this.payments,
    required this.ledgers,
    required this.fees,
    required this.departments,
    required this.promotions,
    required this.students,
  });

  final List<PaymentRow> payments;
  final List<StudentLedger> ledgers;
  final List<FeeRow> fees;
  final List<Department> departments;
  final List<String> promotions;
  final List<User> students;
}

class _PromotionPaymentCard extends StatelessWidget {
  const _PromotionPaymentCard({
    required this.promotion,
    required this.rows,
  });

  final String promotion;
  final List<PaymentRow> rows;

  @override
  Widget build(BuildContext context) {
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
                  '${rows.length} paiements',
                  style: const TextStyle(
                    color: AppColors.success,
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
                  DataColumn(label: Text('Motif')),
                  DataColumn(label: Text('Montant')),
                  DataColumn(label: Text('Date/heure')),
                ],
                rows: rows
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(row.student.fullName)),
                          DataCell(Text(row.student.departmentLabel)),
                          DataCell(Text(row.student.filiereLabel)),
                          DataCell(Text(row.fee.title)),
                          DataCell(Text(formatMoney(row.payment.amount))),
                          DataCell(Text(formatDateTime(row.payment.paidAt))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionTable extends StatelessWidget {
  const _PromotionTable({
    required this.promotions,
    required this.ledgers,
  });

  final List<String> promotions;
  final List<StudentLedger> ledgers;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Departement')),
              DataColumn(label: Text('Filiere')),
              DataColumn(label: Text('Etudiants')),
              DataColumn(label: Text('En ordre')),
              DataColumn(label: Text('Non en ordre')),
              DataColumn(label: Text('Total percu')),
            ],
            rows: promotions.map((promotion) {
              final rows = ledgers.where((ledger) => ledger.student.level == promotion).toList();
              final inOrder = rows.where((ledger) => ledger.isInOrder).length;
              final pending = rows.length - inOrder;
              final totalPaid = rows.fold<double>(0, (sum, row) => sum + row.totalPaid);
              final departments = rows.map((row) => row.student.departmentLabel).toSet().join(', ');
              final filieres = rows.map((row) => row.student.filiereLabel).toSet().join(', ');
              return DataRow(
                cells: [
                  DataCell(Text(promotion)),
                  DataCell(Text(departments.isEmpty ? '-' : departments)),
                  DataCell(Text(filieres.isEmpty ? '-' : filieres)),
                  DataCell(Text('${rows.length}')),
                  DataCell(Text('$inOrder')),
                  DataCell(Text('$pending')),
                  DataCell(Text(formatMoney(totalPaid))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _DepartmentTable extends StatelessWidget {
  const _DepartmentTable({required this.departments});

  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Departement')),
            ],
            rows: departments
                .map(
                  (department) => DataRow(
                    cells: [DataCell(Text(department.name))],
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
