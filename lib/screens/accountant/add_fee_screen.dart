import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/ledger.dart';
import '../../widgets/common_widgets.dart';

class AddFeeScreen extends StatefulWidget {
  const AddFeeScreen({super.key, required this.database, this.existingFee});

  final AppDatabase database;
  final FeeRow? existingFee;

  @override
  State<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends State<AddFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedLevel;
  bool _isLoading = false;

  final List<String> _levels = const [
    'Licence 1',
    'Licence 2',
    'Licence 3',
    'Master 1',
    'Master 2',
  ];

  bool get _isEditing => widget.existingFee != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingFee?.fee.title ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingFee?.fee.amount.toStringAsFixed(0) ?? '',
    );
    _dueDate = widget.existingFee?.fee.dueDate ?? _dueDate;
    _selectedLevel = widget.existingFee?.student.level;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_isEditing && _selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez selectionner une promotion')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await widget.database.updateFee(
          feeId: widget.existingFee!.fee.id,
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          dueDate: _dueDate,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Frais modifies avec succes')),
        );
      } else {
        final count = await widget.database.createFeesByLevel(
          level: _selectedLevel!,
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          dueDate: _dueDate,
        );
        if (!mounted) return;
        if (count > 0) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Frais crees pour $count etudiants de $_selectedLevel',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Aucun etudiant trouve dans la promotion $_selectedLevel',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingFee = widget.existingFee;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le frais' : 'Nouveau frais'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditing && existingFee != null) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(existingFee.student.fullName),
                    subtitle: Text(
                      '${existingFee.student.promotionLabel} - ${existingFee.student.departmentLabel} - ${existingFee.student.filiereLabel}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!_isEditing) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Promotion concernee',
                    prefixIcon: Icon(Icons.layers),
                  ),
                  items: _levels
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedLevel = value),
                  validator: (value) => value == null ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Libelle du frais',
                  hintText: 'Ex: Minerval Tranche 2',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Champ requis'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (CDF)',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value ?? '') == null
                    ? 'Montant invalide'
                    : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date d echeance',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(formatDate(_dueDate)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditing ? 'Enregistrer' : 'Generer les frais'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
