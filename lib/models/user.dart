enum UserRole { student, accountant, administration }

String roleToDatabaseValue(UserRole role) {
  return switch (role) {
    UserRole.student => 'student',
    UserRole.accountant => 'accountant',
    UserRole.administration => 'administration',
  };
}

String roleLabel(UserRole role) {
  return switch (role) {
    UserRole.student => 'Etudiant',
    UserRole.accountant => 'Comptable',
    UserRole.administration => 'Administration',
  };
}

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.matricule,
    this.program,
    this.level,
  });

  final int id;
  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final String? matricule;
  final String? program;
  final String? level;

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: switch (map['role'] as String) {
        'accountant' => UserRole.accountant,
        'administration' => UserRole.administration,
        _ => UserRole.student,
      },
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
      'matricule': matricule,
      'program': program,
      'level': level,
    };
  }
}
