import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/department.dart';
import '../../widgets/common_widgets.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({
    super.key,
    required this.database,
    required this.departments,
  });

  final AppDatabase database;
  final List<Department> departments;

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedPromotion;
  String? _selectedDepartment;
  String? _selectedGender;

  final List<String> _promotions = const [
    'Licence 1',
    'Licence 2',
    'Licence 3',
    'Master 1',
    'Master 2',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.database.createStudent(
        fullName: _fullNameController.text,
        level: _selectedPromotion!,
        program: _selectedDepartment!,
        gender: _selectedGender!,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etudiant preinscrit avec succes')),
      );
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
    final departments = widget.departments;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel etudiant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'L administration cree une preinscription avec le nom complet, la promotion, la filiere et le sexe. L etudiant finalisera ensuite son compte depuis S inscrire.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet de l etudiant',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Champ requis'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedPromotion,
                decoration: const InputDecoration(
                  labelText: 'Promotion',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: _promotions
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedPromotion = value),
                validator: (value) => value == null ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Filiere',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
                items: departments
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value),
                validator: (value) => value == null ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Sexe',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('M')),
                  DropdownMenuItem(value: 'F', child: Text('F')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) => value == null ? 'Champ requis' : null,
              ),
              if (departments.isEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Aucune filiere disponible. Creez d abord une filiere dans l espace admin.',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading || departments.isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer la preinscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
