import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/fee.dart';
import '../../models/ledger.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';

class DGHome extends StatefulWidget {
  const DGHome({
    super.key,
    required this.database,
    required this.user,
    required this.onLogout,
  });

  final AppDatabase database;
  final User user;
  final VoidCallback onLogout;

  @override
  State<DGHome> createState() => _DGHomeState();
}

class _DGHomeState extends State<DGHome> {
  late Future<_DGData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DGData> _load() async {
    final students = await widget.database.students();
    final ledgers = await widget.database.studentLedgers();
    final promotions = await widget.database.promotions();

    final feesByStudent = <int, List<Fee>>{};
    final paymentsByStudent = <int, List<Payment>>{};
    for (final student in students) {
      feesByStudent[student.id] = await widget.database.feesForStudent(
        student.id,
      );
      paymentsByStudent[student.id] = await widget.database.paymentsForStudent(
        student.id,
      );
    }

    return _DGData(
      students: students,
      ledgers: ledgers,
      promotions: promotions,
      feesByStudent: feesByStudent,
      paymentsByStudent: paymentsByStudent,
    );
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
            const Text('Direction Generale', style: TextStyle(fontSize: 14)),
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
      body: FutureBuilder<_DGData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final paidCount = data.ledgers
              .where((ledger) => ledger.isInOrder)
              .length;
          final unpaidCount = data.ledgers.length - paidCount;
          final totalPaid = data.ledgers.fold<double>(
            0,
            (sum, ledger) => sum + ledger.totalPaid,
          );
          final totalDue = data.ledgers.fold<double>(
            0,
            (sum, ledger) => sum + ledger.totalFees,
          );
          final departmentStats = _buildCategoryStats(
            data.ledgers,
            (ledger) => ledger.student.departmentLabel,
          );
          final filiereStats = _buildCategoryStats(
            data.ledgers,
            (ledger) => ledger.student.filiereLabel,
          );

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
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
                        title: 'Etudiants',
                        value: '${data.students.length}',
                        icon: Icons.people_alt_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: SummaryCard(
                        title: 'Payes',
                        value: '$paidCount',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: SummaryCard(
                        title: 'Non payes',
                        value: '$unpaidCount',
                        icon: Icons.cancel_outlined,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: SummaryCard(
                        title: 'Montant percu',
                        value: formatMoney(totalPaid),
                        icon: Icons.payments_outlined,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionTitle(
                  title: 'Statistiques par departement',
                  trailing: '${departmentStats.length} departements',
                ),
                if (departmentStats.isEmpty)
                  const EmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'Aucun departement',
                    message:
                        'Les statistiques par departement apparaitront ici.',
                  )
                else
                  _CategoryStatsTable(stats: departmentStats),
                const SizedBox(height: 24),
                SectionTitle(
                  title: 'Statistiques par filiere',
                  trailing: '${filiereStats.length} filieres',
                ),
                if (filiereStats.isEmpty)
                  const EmptyState(
                    icon: Icons.account_tree_outlined,
                    title: 'Aucune filiere',
                    message:
                        'Les statistiques par filiere apparaitront ici.',
                  )
                else
                  _CategoryStatsTable(stats: filiereStats),
                const SizedBox(height: 24),
                SectionTitle(
                  title: 'Tableaux par promotion',
                  trailing: '${data.promotions.length} promotions',
                ),
                if (data.promotions.isEmpty)
                  const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'Aucune promotion',
                    message:
                        'Les promotions seront visibles ici quand les etudiants seront enregistres.',
                  )
                else
                  ...data.promotions.map(
                    (promotion) => _PromotionStatusCard(
                      promotion: promotion,
                      ledgers: data.ledgers
                          .where((ledger) => ledger.student.level == promotion)
                          .toList(),
                      feesByStudent: data.feesByStudent,
                      paymentsByStudent: data.paymentsByStudent,
                    ),
                  ),
                const SizedBox(height: 24),
                SummaryCard(
                  title: 'Total attendu',
                  value: formatMoney(totalDue),
                  icon: Icons.account_balance,
                  color: AppColors.primary,
                ),
              ],
            ),
          );
        },
      ),
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
                color: AppColors.success.withValues(alpha: 0.08),
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
                    'Vue DG',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Text(
                  //   'Les paiements sont affiches en vert quand ils sont en ordre, et en rouge sinon.',
                  //   style: TextStyle(color: Colors.grey),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DGData {
  const _DGData({
    required this.students,
    required this.ledgers,
    required this.promotions,
    required this.feesByStudent,
    required this.paymentsByStudent,
  });

  final List<User> students;
  final List<StudentLedger> ledgers;
  final List<String> promotions;
  final Map<int, List<Fee>> feesByStudent;
  final Map<int, List<Payment>> paymentsByStudent;
}

class _CategoryStat {
  const _CategoryStat({
    required this.label,
    required this.count,
    required this.inOrder,
    required this.pending,
    required this.totalPaid,
    required this.totalDue,
  });

  final String label;
  final int count;
  final int inOrder;
  final int pending;
  final double totalPaid;
  final double totalDue;
}

List<_CategoryStat> _buildCategoryStats(
  List<StudentLedger> ledgers,
  String Function(StudentLedger ledger) selector,
) {
  final grouped = <String, List<StudentLedger>>{};
  for (final ledger in ledgers) {
    final key = selector(ledger);
    grouped.putIfAbsent(key, () => []).add(ledger);
  }

  final stats = grouped.entries.map((entry) {
    final rows = entry.value;
    final inOrder = rows.where((ledger) => ledger.isInOrder).length;
    final pending = rows.length - inOrder;
    final totalPaid = rows.fold<double>(0, (sum, row) => sum + row.totalPaid);
    final totalDue = rows.fold<double>(0, (sum, row) => sum + row.totalFees);
    return _CategoryStat(
      label: entry.key,
      count: rows.length,
      inOrder: inOrder,
      pending: pending,
      totalPaid: totalPaid,
      totalDue: totalDue,
    );
  }).toList();

  stats.sort((a, b) => a.label.compareTo(b.label));
  return stats;
}

class _CategoryStatsTable extends StatelessWidget {
  const _CategoryStatsTable({required this.stats});

  final List<_CategoryStat> stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Libelle')),
              DataColumn(label: Text('Etudiants')),
              DataColumn(label: Text('En ordre')),
              DataColumn(label: Text('En attente')),
              DataColumn(label: Text('Total attendu')),
              DataColumn(label: Text('Total percu')),
            ],
            rows: stats
                .map(
                  (stat) => DataRow(
                    cells: [
                      DataCell(Text(stat.label)),
                      DataCell(Text('${stat.count}')),
                      DataCell(Text('${stat.inOrder}')),
                      DataCell(Text('${stat.pending}')),
                      DataCell(Text(formatMoney(stat.totalDue))),
                      DataCell(Text(formatMoney(stat.totalPaid))),
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

class _PromotionStatusCard extends StatelessWidget {
  const _PromotionStatusCard({
    required this.promotion,
    required this.ledgers,
    required this.feesByStudent,
    required this.paymentsByStudent,
  });

  final String promotion;
  final List<StudentLedger> ledgers;
  final Map<int, List<Fee>> feesByStudent;
  final Map<int, List<Payment>> paymentsByStudent;

  @override
  Widget build(BuildContext context) {
    final paidCount = ledgers.where((ledger) => ledger.isInOrder).length;

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
                  '$paidCount / ${ledgers.length} en ordre',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: paidCount == ledgers.length
                        ? AppColors.success
                        : AppColors.warning,
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
                  DataColumn(label: Text('Statut')),
                ],
                rows: ledgers.map((ledger) {
                  final inOrder = ledger.isInOrder;
                  final fees =
                      feesByStudent[ledger.student.id] ?? const <Fee>[];
                  final payments =
                      paymentsByStudent[ledger.student.id] ?? const <Payment>[];
                  final motif = _paymentMotif(fees, payments, inOrder);
                  return DataRow(
                    color: MaterialStatePropertyAll(
                      inOrder
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.error.withValues(alpha: 0.08),
                    ),
                    cells: [
                      DataCell(Text(ledger.student.fullName)),
                      DataCell(Text(ledger.student.departmentLabel)),
                      DataCell(Text(ledger.student.filiereLabel)),
                      DataCell(Text(motif)),
                      DataCell(Text(formatMoney(ledger.totalPaid))),
                      DataCell(
                        Text(
                          inOrder ? 'Paye' : 'En attente',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inOrder
                                ? AppColors.success
                                : AppColors.error,
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

  String _paymentMotif(List<Fee> fees, List<Payment> payments, bool inOrder) {
    if (payments.isNotEmpty) {
      if (fees.isEmpty) {
        return 'Paiement valide';
      }
      final match = fees
          .where((fee) => fee.id == payments.first.feeId)
          .toList();
      return match.isNotEmpty ? match.first.title : fees.first.title;
    }
    if (fees.isEmpty) {
      return 'Aucun frais';
    }
    return fees.first.title;
  }
}
