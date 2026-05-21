import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../models/user.dart';
import '../../models/ledger.dart';
import '../../widgets/common_widgets.dart';
import 'add_student_screen.dart';

class AdministrationHome extends StatefulWidget {
  final AppDatabase database;
  final User user;
  final VoidCallback onLogout;

  const AdministrationHome({
    super.key,
    required this.database,
    required this.user,
    required this.onLogout,
  });

  @override
  State<AdministrationHome> createState() => _AdministrationHomeState();
}

class _AdministrationHomeState extends State<AdministrationHome> {
  late Future<_AdminData> _future;
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminData> _load() async {
    final students = await widget.database.students();
    final ledgers = await widget.database.studentLedgers();
    return _AdminData(students: students, ledgers: ledgers);
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
        title: const Text('Administration'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: FutureBuilder<_AdminData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;

          final totalDue = data.ledgers.fold<double>(0, (s, l) => s + l.totalFees);
          final totalPaid = data.ledgers.fold<double>(0, (s, l) => s + l.totalPaid);

          final filteredLedgers = data.ledgers.where((l) {
            if (_filter == 'En ordre') return l.isInOrder;
            if (_filter == 'Non en ordre') return !l.isInOrder;
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsRow(totalDue, totalPaid),
              const SizedBox(height: 24),
              _buildFilterChips(),
              const SizedBox(height: 16),
              SectionTitle(
                title: 'Liste des étudiants',
                trailing: '${filteredLedgers.length} étudiants',
              ),
              if (filteredLedgers.isEmpty)
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'Aucun résultat',
                  message: 'Aucun étudiant ne correspond à ce filtre.',
                )
              else
                ...filteredLedgers.map((l) => _StudentLedgerTile(ledger: l)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudent,
        label: const Text('Nouvel Étudiant'),
        icon: const Icon(Icons.person_add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
            title: 'Total Perçu',
            value: formatMoney(totalPaid),
            icon: Icons.payments,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: ['Tous', 'En ordre', 'Non en ordre'].map((f) {
        final selected = _filter == f;
        return FilterChip(
          label: Text(f),
          selected: selected,
          onSelected: (v) => setState(() => _filter = f),
          selectedColor: AppColors.accent.withOpacity(0.2),
          checkmarkColor: AppColors.accent,
        );
      }).toList(),
    );
  }

  void _showAddStudent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentScreen(database: widget.database),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }
}

class _AdminData {
  final List<User> students;
  final List<StudentLedger> ledgers;
  _AdminData({required this.students, required this.ledgers});
}

class _StudentLedgerTile extends StatelessWidget {
  final StudentLedger ledger;

  const _StudentLedgerTile({required this.ledger});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ledger.isInOrder ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
          child: Icon(
            ledger.isInOrder ? Icons.check : Icons.warning_amber_rounded,
            color: ledger.isInOrder ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(ledger.student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${ledger.student.matricule} • ${ledger.student.level}'),
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
