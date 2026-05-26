import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.database});

  final AppDatabase database;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isChecking = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  User? _matchedStudent;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription etudiant')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _nameFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etape 1 : verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saisissez exactement le nom complet enregistre par l administration.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isChecking ? null : _verifyStudent,
                      child: _isChecking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verifier mon nom'),
                    ),
                    if (_matchedStudent != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Nom trouve: ${_matchedStudent!.fullName}\nClasse: ${_matchedStudent!.classLabel}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _accountFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etape 2 : validation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ajoutez votre email et votre mot de passe pour activer le compte.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled:
                          _matchedStudent != null &&
                          !_matchedStudent!.hasCompletedRegistration,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Adresse email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (_matchedStudent == null ||
                            _matchedStudent!.hasCompletedRegistration) {
                          return null;
                        }
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Champ requis';
                        if (!email.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled:
                          _matchedStudent != null &&
                          !_matchedStudent!.hasCompletedRegistration,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (_matchedStudent == null ||
                            _matchedStudent!.hasCompletedRegistration) {
                          return null;
                        }
                        if ((value?.trim().length ?? 0) < 6) {
                          return 'Minimum 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          _matchedStudent == null ||
                              _matchedStudent!.hasCompletedRegistration ||
                              _isSubmitting
                          ? null
                          : _submitRegistration,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Valider mon inscription'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyStudent() async {
    if (!_nameFormKey.currentState!.validate()) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _matchedStudent = null;
    });

    try {
      final student = await widget.database.findStudentByFullName(
        _fullNameController.text,
      );
      if (!mounted) return;

      if (student == null) {
        setState(() {
          _errorMessage = 'Aucun etudiant ne correspond a ce nom.';
        });
      } else if (student.hasCompletedRegistration) {
        setState(() {
          _matchedStudent = student;
          _errorMessage = 'Cet etudiant a deja valide son inscription.';
        });
      } else {
        setState(() {
          _matchedStudent = student;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de verifier le nom pour le moment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (!_accountFormKey.currentState!.validate() || _matchedStudent == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.database.completeStudentRegistration(
        studentId: _matchedStudent!.id,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inscription validee. Vous pouvez maintenant vous connecter.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Validation impossible. Cet email est peut etre deja utilise.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
