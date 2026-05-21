import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  final AppDatabase database;
  final ValueChanged<User> onLoggedIn;

  const LoginScreen({
    super.key,
    required this.database,
    required this.onLoggedIn,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'alice@univ.local');
  final _passwordController = TextEditingController(text: 'etudiant123');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 80, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Text(
                  'Gestion des Frais Académiques',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Comptes de test:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    _TestAccountChip(
                      label: 'Etudiant',
                      onTap: () => _fill('alice@univ.local', 'etudiant123'),
                    ),
                    _TestAccountChip(
                      label: 'Admin',
                      onTap: () => _fill('admin@univ.local', 'admin123'),
                    ),
                    _TestAccountChip(
                      label: 'Comptable',
                      onTap: () => _fill('comptable@univ.local', 'comptable123'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fill(String email, String pass) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = pass;
    });
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await widget.database.login(_emailController.text, _passwordController.text);
      if (user != null) {
        widget.onLoggedIn(user);
      } else {
        setState(() => _errorMessage = 'Identifiants incorrects');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _TestAccountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TestAccountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
