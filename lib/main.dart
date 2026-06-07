import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/app_database.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/budget/budget_admin_home.dart';
import 'screens/direction/dg_home.dart';
import 'screens/accountant/accountant_home.dart';
import 'screens/student/student_home.dart';
import 'screens/splash_screen.dart';
import 'widgets/common_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final db = AppDatabase();
  await db.init();

  runApp(AcademicFeesApp(database: db));
}

class AcademicFeesApp extends StatefulWidget {
  final AppDatabase database;
  const AcademicFeesApp({super.key, required this.database});

  @override
  State<AcademicFeesApp> createState() => _AcademicFeesAppState();
}

class _AcademicFeesAppState extends State<AcademicFeesApp> {
  User? _currentUser;
  bool _showSplash = true;

  void _setUser(User? user) => setState(() => _currentUser = user);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ISP Lubumbashi - Plateforme de frais academiques',
      theme: AppTheme.light,
      home: _showSplash
          ? SplashScreen(
              onInitializationComplete: () {
                setState(() {
                  _showSplash = false;
                });
              },
            )
          : _currentUser == null
          ? LoginScreen(database: widget.database, onLoggedIn: _setUser)
          : _buildRoleHome(),
    );
  }

  Widget _buildRoleHome() {
    final user = _currentUser!;
    return switch (user.role) {
      UserRole.student => StudentHome(
        database: widget.database,
        user: user,
        onLogout: () => _setUser(null),
      ),
      UserRole.budgetAdmin => BudgetAdminHome(
        database: widget.database,
        user: user,
        onLogout: () => _setUser(null),
      ),
      UserRole.dg => DGHome(
        database: widget.database,
        user: user,
        onLogout: () => _setUser(null),
      ),
      UserRole.accountant => AccountantHome(
        database: widget.database,
        user: user,
        onLogout: () => _setUser(null),
      ),
    };
  }
}
