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
  final _programController = TextEditingController();
  bool _isLoading = false;
  String? _selectedPromotion;
  String? _selectedDepartment;
  String? _selectedProgram;
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
    _programController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDepartment == null || _selectedProgram == null || _selectedProgram!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez selectionner un departement et une filiere')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.database.createStudent(
        fullName: _fullNameController.text,
        department: _selectedDepartment!,
        level: _selectedPromotion!,
        program: _selectedProgram!.trim(),
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
    final programs = _programsForDepartment(_selectedDepartment);
    final hasProgramChoices = programs.isNotEmpty;

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
                'L administration cree une preinscription avec le nom complet, le departement, la filiere, la promotion et le sexe. L etudiant finalisera ensuite son compte depuis S inscrire.',
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
                  labelText: 'Departement',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: departments
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                    _selectedProgram = null;
                    _programController.clear();
                  });
                },
                validator: (value) => value == null ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              if (hasProgramChoices)
                DropdownButtonFormField<String>(
                  initialValue: _selectedProgram,
                  decoration: const InputDecoration(
                    labelText: 'Filiere',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  items: programs
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedProgram = value),
                  validator: (value) => value == null ? 'Champ requis' : null,
                )
              else
                TextFormField(
                  controller: _programController,
                  decoration: const InputDecoration(
                    labelText: 'Filiere',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  onChanged: (value) =>
                      setState(() => _selectedProgram = value),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
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
                  'Aucun departement disponible. Creez d abord un departement dans l espace admin.',
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

  List<String> _programsForDepartment(String? department) {
    return switch (department) {
      'Sciences et technologies' => const [
          'Informatique de gestion',
          'Genie logiciel',
          'Reseaux et telecommunications',
        ],
      'Sciences economiques et de gestion' => const [
          'Sciences economiques',
          'Gestion des ressources humaines',
          'Comptabilite',
        ],
      'Droit et sciences politiques' => const [
          'Droit',
          'Sciences politiques',
          'Relations internationales',
        ],
      'Lettres et sciences humaines' => const [
          'Litterature',
          'Communication',
          'Histoire',
        ],
      _ => const [],
    };
  }
}
