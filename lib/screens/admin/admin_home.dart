import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/department.dart';
import '../../models/ledger.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';
import 'add_student_screen.dart';

class AdministrationHome extends StatefulWidget {
  const AdministrationHome({
    super.key,
    required this.database,
    required this.user,
    required this.onLogout,
  });

  final AppDatabase database;
  final User user;
  final VoidCallback onLogout;

  @override
  State<AdministrationHome> createState() => _AdministrationHomeState();
}

class _AdministrationHomeState extends State<AdministrationHome> {
  late Future<_AdminData> _future;
  final _departmentController = TextEditingController();
  String _ledgerFilter = 'Tous';
  String _registrationFilter = 'Tous';

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

  Future<_AdminData> _load() async {
    final students = await widget.database.students();
    final ledgers = await widget.database.studentLedgers();
    final departments = await widget.database.departments();
    return _AdminData(
      students: students,
      ledgers: ledgers,
      departments: departments,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: FutureBuilder<_AdminData>(
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

          final filteredLedgers = data.ledgers.where((ledger) {
            if (_ledgerFilter == 'En ordre') {
              return ledger.isInOrder;
            }
            if (_ledgerFilter == 'Non en ordre') {
              return !ledger.isInOrder;
            }
            return true;
          }).toList();

          final filteredStudents = data.students.where((student) {
            if (_registrationFilter == 'Valides') {
              return student.hasCompletedRegistration;
            }
            if (_registrationFilter == 'En attente') {
              return !student.hasCompletedRegistration;
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDepartmentSection(data.departments),
              const SizedBox(height: 24),
              _buildStatsRow(totalDue, totalPaid),
              const SizedBox(height: 24),
              _buildLedgerFilterChips(),
              const SizedBox(height: 16),
              SectionTitle(
                title: 'Situation financiere',
                trailing: '${filteredLedgers.length} etudiants',
              ),
              if (filteredLedgers.isEmpty)
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'Aucun resultat',
                  message: 'Aucun etudiant ne correspond a ce filtre.',
                )
              else
                ...filteredLedgers.map(
                  (ledger) => _StudentLedgerTile(ledger: ledger),
                ),
              const SizedBox(height: 24),
              _buildRegistrationFilterChips(),
              const SizedBox(height: 16),
              SectionTitle(
                title: 'Suivi des inscriptions',
                trailing: '${filteredStudents.length} comptes',
              ),
              if (filteredStudents.isEmpty)
                const EmptyState(
                  icon: Icons.person_search,
                  title: 'Aucun compte',
                  message: 'Aucun etudiant ne correspond a ce statut.',
                )
              else
                ...filteredStudents.map(
                  (student) => _RegistrationTile(student: student),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<_AdminData>(
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

  Widget _buildStatsRow(double totalDue, double totalPaid) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Total Attendu',
            value: formatMoney(totalDue),
            icon: Icons.account_balance,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(
            title: 'Total Percu',
            value: formatMoney(totalPaid),
            icon: Icons.payments,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerFilterChips() {
    return Wrap(
      spacing: 8,
      children: ['Tous', 'En ordre', 'Non en ordre'].map((filter) {
        return FilterChip(
          label: Text(filter),
          selected: _ledgerFilter == filter,
          onSelected: (_) => setState(() => _ledgerFilter = filter),
          selectedColor: AppColors.accent.withValues(alpha: 0.2),
          checkmarkColor: AppColors.accent,
        );
      }).toList(),
    );
  }

  Widget _buildRegistrationFilterChips() {
    return Wrap(
      spacing: 8,
      children: ['Tous', 'Valides', 'En attente'].map((filter) {
        return FilterChip(
          label: Text(filter),
          selected: _registrationFilter == filter,
          onSelected: (_) => setState(() => _registrationFilter = filter),
          selectedColor: AppColors.success.withValues(alpha: 0.16),
          checkmarkColor: AppColors.success,
        );
      }).toList(),
    );
  }
}

class _AdminData {
  const _AdminData({
    required this.students,
    required this.ledgers,
    required this.departments,
  });

  final List<User> students;
  final List<StudentLedger> ledgers;
  final List<Department> departments;
}

class _StudentLedgerTile extends StatelessWidget {
  const _StudentLedgerTile({required this.ledger});

  final StudentLedger ledger;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ledger.isInOrder
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          child: Icon(
            ledger.isInOrder ? Icons.check : Icons.warning_amber_rounded,
            color: ledger.isInOrder ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(
          ledger.student.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${ledger.student.departmentLabel} - ${ledger.student.promotionLabel} - ${ledger.student.filiereLabel}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(ledger.paymentPercentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ledger.isInOrder ? AppColors.success : AppColors.warning,
              ),
            ),
            Text(
              formatMoney(ledger.balance),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationTile extends StatelessWidget {
  const _RegistrationTile({required this.student});

  final User student;

  @override
  Widget build(BuildContext context) {
    final isValidated = student.hasCompletedRegistration;
    final color = isValidated ? AppColors.success : AppColors.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isValidated ? Icons.verified_user_outlined : Icons.hourglass_bottom,
            color: color,
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isValidated
              ? '${student.email} - ${student.departmentLabel} - ${student.promotionLabel} - ${student.filiereLabel} - ${student.genderLabel}'
              : 'En attente de validation - ${student.departmentLabel} - ${student.promotionLabel} - ${student.filiereLabel} - ${student.genderLabel}',
        ),
        trailing: Text(
          isValidated ? 'Valide' : 'En attente',
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
