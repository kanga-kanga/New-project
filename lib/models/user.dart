enum UserRole { student, accountant, budgetAdmin, dg }

String roleToDatabaseValue(UserRole role) {
  return switch (role) {
    UserRole.student => 'student',
    UserRole.accountant => 'accountant',
    UserRole.budgetAdmin => 'budget_admin',
    UserRole.dg => 'administration',
  };
}

String roleLabel(UserRole role) {
  return switch (role) {
    UserRole.student => 'Etudiant',
    UserRole.accountant => 'Tresorerie',
    UserRole.budgetAdmin => 'Administrateur Budget',
    UserRole.dg => 'DG',
  };
}

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    required this.registrationCompleted,
    this.gender,
    this.matricule,
    this.program,
    this.level,
  });

  final int id;
  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final bool registrationCompleted;
  final String? gender;
  final String? matricule;
  final String? program;
  final String? level;

  bool get hasCompletedRegistration => registrationCompleted;

  String get classLabel {
    final value = level?.trim() ?? '';
    return value.isEmpty ? 'Classe non definie' : value;
  }

  String get promotionLabel {
    final value = level?.trim() ?? '';
    return value.isEmpty ? 'Promotion non definie' : value;
  }

  String get departmentLabel {
    final value = program?.trim() ?? '';
    return value.isEmpty ? 'Filiere non definie' : value;
  }

  String get genderLabel {
    final value = gender?.trim().toUpperCase() ?? '';
    if (value == 'M' || value == 'F') {
      return value;
    }
    return 'Non precise';
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: switch (map['role'] as String) {
        'accountant' => UserRole.accountant,
        'budget_admin' => UserRole.budgetAdmin,
        'dg' => UserRole.dg,
        'administration' => UserRole.dg,
        _ => UserRole.student,
      },
      registrationCompleted:
          ((map['registration_completed'] as int?) ?? 1) == 1,
      gender: map['gender'] as String?,
      matricule: map['matricule'] as String?,
      program: map['program'] as String?,
      level: map['level'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': roleToDatabaseValue(role),
      'registration_completed': registrationCompleted ? 1 : 0,
      'gender': gender,
      'matricule': matricule,
      'program': program,
      'level': level,
    };
  }
}
