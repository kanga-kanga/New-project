import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/department.dart';
import '../models/fee.dart';
import '../models/ledger.dart';
import '../models/payment.dart';
import '../models/user.dart';

class AppDatabase {
  Database? _db;

  Future<void> init() async {
    final options = OpenDatabaseOptions(
      version: 4,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _ensureAdministrationAccount(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN registration_completed INTEGER NOT NULL DEFAULT 1',
          );
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE users ADD COLUMN gender TEXT');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS departments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL
            )
          ''');
          await _seedDepartments(db);
        }
      },
    );

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      _db = await databaseFactory.openDatabase(
        'academic_fees.db',
        options: options,
      );
    } else {
      final databasePath = await getDatabasesPath();
      final path = p.join(databasePath, 'academic_fees.db');
      _db = await openDatabase(
        path,
        version: options.version,
        onCreate: options.onCreate,
        onUpgrade: options.onUpgrade,
      );
    }

    await _ensureCoreAccounts(_db!);
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        registration_completed INTEGER NOT NULL DEFAULT 1,
        gender TEXT,
        matricule TEXT,
        program TEXT,
        level TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE fees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY(student_id) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fee_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        method TEXT NOT NULL,
        reference TEXT NOT NULL,
        paid_at TEXT NOT NULL,
        FOREIGN KEY(fee_id) REFERENCES fees(id),
        FOREIGN KEY(student_id) REFERENCES users(id)
      )
    ''');
  }

  Database get db {
    final current = _db;
    if (current == null) {
      throw StateError('La base de donnees n est pas initialisee.');
    }
    return current;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _seed(Database db) async {
    await _seedDepartments(db);

    final accountantId = await db.insert('users', {
      'full_name': 'Grace Mbala',
      'email': 'tresorerie@univ.local',
      'password': 'comptable123',
      'role': 'accountant',
      'gender': 'F',
    });

    final aliceId = await db.insert('users', {
      'full_name': 'Alice Kabamba',
      'email': 'alice@univ.local',
      'password': 'etudiant123',
      'role': 'student',
      'registration_completed': 1,
      'gender': 'F',
      'matricule': 'ETU-2026-001',
      'program': 'Informatique de gestion',
      'level': 'Licence 2',
    });

    final davidId = await db.insert('users', {
      'full_name': 'David Mutombo',
      'email': 'david@univ.local',
      'password': 'etudiant123',
      'role': 'student',
      'registration_completed': 1,
      'gender': 'M',
      'matricule': 'ETU-2026-002',
      'program': 'Sciences economiques',
      'level': 'Licence 3',
    });

    final now = DateTime.now();
    await db.insert('fees', {
      'student_id': aliceId,
      'title': 'Frais academiques - Tranche 1',
      'amount': 450,
      'due_date': now.add(const Duration(days: 14)).toIso8601String(),
      'status': 'pending',
      'created_at': now.toIso8601String(),
    });
    final aliceFee2 = await db.insert('fees', {
      'student_id': aliceId,
      'title': 'Frais de laboratoire',
      'amount': 95,
      'due_date': now.add(const Duration(days: 30)).toIso8601String(),
      'status': 'paid',
      'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
    });
    await db.insert('payments', {
      'fee_id': aliceFee2,
      'student_id': aliceId,
      'amount': 95,
      'method': 'Mobile Money simule',
      'reference': 'SIM-${100000 + accountantId + aliceFee2}',
      'paid_at': now.subtract(const Duration(days: 5)).toIso8601String(),
    });
    await db.insert('fees', {
      'student_id': davidId,
      'title': 'Frais academiques - Tranche 1',
      'amount': 450,
      'due_date': now.add(const Duration(days: 7)).toIso8601String(),
      'status': 'pending',
      'created_at': now.toIso8601String(),
    });
  }

  Future<void> _seedDepartments(Database db) async {
    final departments = [
      'Informatique de gestion',
      'Sciences economiques',
      'Droit',
      'Gestion des ressources humaines',
    ];
    final now = DateTime.now().toIso8601String();
    for (final name in departments) {
      await db.insert('departments', {
        'name': name,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _ensureAdministrationAccount(Database db) async {
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: ['admin@univ.local'],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }

    await db.insert('users', {
      'full_name': 'Administration Universitaire',
      'email': 'admin@univ.local',
      'password': 'admin123',
      'role': 'administration',
    });
  }

  Future<void> _ensureCoreAccounts(Database db) async {
    await _ensureAccount(
      db,
      email: 'admin@univ.local',
      fullName: 'Administration Universitaire',
      password: 'admin123',
      role: 'administration',
    );
    await _ensureAccount(
      db,
      email: 'budget@univ.local',
      fullName: 'Budget Universitaire',
      password: 'budget123',
      role: 'budget_admin',
    );
    await _ensureAccount(
      db,
      email: 'tresorerie@univ.local',
      fullName: 'Grace Mbala',
      password: 'comptable123',
      role: 'accountant',
      gender: 'F',
    );
  }

  Future<void> _ensureAccount(
    Database db, {
    required String email,
    required String fullName,
    required String password,
    required String role,
    String? gender,
  }) async {
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }

    await db.insert('users', {
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
      if (gender != null) 'gender': gender,
    });
  }

  Future<User?> login(String email, String password) async {
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  Future<List<Department>> departments() async {
    final rows = await db.query('departments', orderBy: 'name ASC');
    return rows.map(Department.fromMap).toList();
  }

  Future<void> createDepartment(String name) async {
    await db.insert('departments', {
      'name': name.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<User>> students() async {
    final rows = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['student'],
      orderBy: 'full_name ASC',
    );
    return rows.map(User.fromMap).toList();
  }

  Future<List<String>> promotions() async {
    final rows = await db.rawQuery('''
      SELECT DISTINCT level
      FROM users
      WHERE role = 'student' AND level IS NOT NULL AND TRIM(level) <> ''
      ORDER BY level ASC
    ''');
    return rows
        .map((row) => row['level'] as String)
        .where((level) => level.trim().isNotEmpty)
        .toList();
  }

  Future<int> createStudent({
    required String fullName,
    required String level,
    required String program,
    required String gender,
  }) async {
    final token = DateTime.now().microsecondsSinceEpoch;
    return db.insert('users', {
      'full_name': fullName.trim(),
      'email': 'pending-$token@preinscription.local',
      'password': '',
      'role': 'student',
      'registration_completed': 0,
      'gender': gender.trim().toUpperCase(),
      'matricule': '',
      'program': program.trim(),
      'level': level.trim(),
    });
  }

  Future<User?> findStudentByFullName(String fullName) async {
    final rows = await db.query(
      'users',
      where: 'role = ? AND LOWER(TRIM(full_name)) = ?',
      whereArgs: ['student', fullName.trim().toLowerCase()],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  Future<void> completeStudentRegistration({
    required int studentId,
    required String email,
    required String password,
  }) async {
    await db.update(
      'users',
      {
        'email': email.trim().toLowerCase(),
        'password': password,
        'registration_completed': 1,
      },
      where: 'id = ? AND role = ?',
      whereArgs: [studentId, 'student'],
    );
  }

  Future<List<Fee>> feesForStudent(int studentId) async {
    final rows = await db.query(
      'fees',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'status ASC, due_date ASC',
    );
    return rows.map(Fee.fromMap).toList();
  }

  Future<List<Payment>> paymentsForStudent(int studentId) async {
    final rows = await db.query(
      'payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'paid_at DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<PaymentRow>> recentPayments() async {
    final rows = await db.rawQuery('''
      SELECT
        payments.id AS payment_id,
        payments.fee_id,
        payments.student_id,
        payments.amount AS payment_amount,
        payments.method,
        payments.reference,
        payments.paid_at,
        users.id AS user_id,
        users.full_name,
        users.email,
        users.password,
        users.role,
        users.registration_completed,
        users.gender,
        users.matricule,
        users.program,
        users.level,
        fees.id AS fee_row_id,
        fees.title,
        fees.amount AS fee_amount,
        fees.due_date,
        fees.status,
        fees.created_at
      FROM payments
      INNER JOIN users ON users.id = payments.student_id
      INNER JOIN fees ON fees.id = payments.fee_id
      ORDER BY payments.paid_at DESC
    ''');

    return rows.map(_paymentRowFromMap).toList();
  }

  Future<List<FeeRow>> allFees() async {
    final rows = await db.rawQuery('''
      SELECT
        fees.id AS fee_row_id,
        fees.student_id,
        fees.title,
        fees.amount AS fee_amount,
        fees.due_date,
        fees.status,
        fees.created_at,
        users.id AS user_id,
        users.full_name,
        users.email,
        users.password,
        users.role,
        users.registration_completed,
        users.gender,
        users.matricule,
        users.program,
        users.level
      FROM fees
      INNER JOIN users ON users.id = fees.student_id
      ORDER BY fees.created_at DESC, fees.due_date ASC
    ''');

    return rows.map((row) {
      return FeeRow(
        fee: Fee.fromMap({
          'id': row['fee_row_id'],
          'student_id': row['student_id'],
          'title': row['title'],
          'amount': row['fee_amount'],
          'due_date': row['due_date'],
          'status': row['status'],
          'created_at': row['created_at'],
        }),
        student: _userFromJoinedMap(row),
      );
    }).toList();
  }

  PaymentRow _paymentRowFromMap(Map<String, Object?> row) {
    return PaymentRow(
      payment: Payment(
        id: row['payment_id'] as int,
        feeId: row['fee_id'] as int,
        studentId: row['student_id'] as int,
        amount: (row['payment_amount'] as num).toDouble(),
        method: row['method'] as String,
        reference: row['reference'] as String,
        paidAt: DateTime.parse(row['paid_at'] as String),
      ),
      student: _userFromJoinedMap(row),
      fee: Fee.fromMap({
        'id': row['fee_row_id'],
        'student_id': row['student_id'],
        'title': row['title'],
        'amount': row['fee_amount'],
        'due_date': row['due_date'],
        'status': row['status'],
        'created_at': row['created_at'],
      }),
    );
  }

  User _userFromJoinedMap(Map<String, Object?> row) {
    return User.fromMap({
      'id': row['user_id'],
      'full_name': row['full_name'],
      'email': row['email'],
      'password': row['password'],
      'role': row['role'],
      'registration_completed': row['registration_completed'],
      'gender': row['gender'],
      'matricule': row['matricule'],
      'program': row['program'],
      'level': row['level'],
    });
  }

  Future<List<StudentLedger>> studentLedgers() async {
    final result = <StudentLedger>[];
    for (final student in await students()) {
      final fees = await feesForStudent(student.id);
      final payments = await paymentsForStudent(student.id);
      final totalFees = fees.fold<double>(0, (sum, fee) => sum + fee.amount);
      final totalPaid = payments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );
      result.add(
        StudentLedger(
          student: student,
          totalFees: totalFees,
          totalPaid: totalPaid,
          balance: totalFees - totalPaid,
          feesCount: fees.length,
        ),
      );
    }
    return result;
  }

  Future<void> createFee({
    required int studentId,
    required String title,
    required double amount,
    required DateTime dueDate,
  }) async {
    await db.insert('fees', {
      'student_id': studentId,
      'title': title.trim(),
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> createFeesByLevel({
    required String level,
    required String title,
    required double amount,
    required DateTime dueDate,
  }) async {
    final students = await db.query(
      'users',
      where: 'role = ? AND level = ?',
      whereArgs: ['student', level],
    );

    if (students.isEmpty) {
      return 0;
    }

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final due = dueDate.toIso8601String();
      for (final student in students) {
        await txn.insert('fees', {
          'student_id': student['id'],
          'title': title.trim(),
          'amount': amount,
          'due_date': due,
          'status': 'pending',
          'created_at': now,
        });
      }
    });

    return students.length;
  }

  Future<void> updateFee({
    required int feeId,
    required String title,
    required double amount,
    required DateTime dueDate,
  }) async {
    await db.update(
      'fees',
      {
        'title': title.trim(),
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [feeId],
    );
  }

  Future<void> deleteFee(int feeId) async {
    await db.transaction((txn) async {
      await txn.delete('payments', where: 'fee_id = ?', whereArgs: [feeId]);
      await txn.delete('fees', where: 'id = ?', whereArgs: [feeId]);
    });
  }

  Future<Payment> recordExternalPayment(
    Fee fee, {
    required String method,
    required String accountNumber,
    required String reference,
    required String gateway,
    String? status,
  }) async {
    final maskedAccount = accountNumber.length > 4
        ? '***${accountNumber.substring(accountNumber.length - 4)}'
        : accountNumber;

    return db.transaction((txn) async {
      await txn.update(
        'fees',
        {'status': 'paid'},
        where: 'id = ?',
        whereArgs: [fee.id],
      );
      final paymentId = await txn.insert('payments', {
        'fee_id': fee.id,
        'student_id': fee.studentId,
        'amount': fee.amount,
        'method':
            '$gateway - $method - $maskedAccount${status != null ? ' - $status' : ''}',
        'reference': reference,
        'paid_at': DateTime.now().toIso8601String(),
      });
      final row = (await txn.query(
        'payments',
        where: 'id = ?',
        whereArgs: [paymentId],
      )).first;
      return Payment.fromMap(row);
    });
  }

  Future<Payment> simulatePayment(
    Fee fee, {
    required String method,
    required String accountNumber,
  }) async {
    final reference =
        'SIM-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';
    final account = accountNumber.length > 4
        ? '***${accountNumber.substring(accountNumber.length - 4)}'
        : accountNumber;

    return db.transaction((txn) async {
      await txn.update(
        'fees',
        {'status': 'paid'},
        where: 'id = ?',
        whereArgs: [fee.id],
      );
      final paymentId = await txn.insert('payments', {
        'fee_id': fee.id,
        'student_id': fee.studentId,
        'amount': fee.amount,
        'method': '$method - $account',
        'reference': reference,
        'paid_at': DateTime.now().toIso8601String(),
      });
      final row = (await txn.query(
        'payments',
        where: 'id = ?',
        whereArgs: [paymentId],
      )).first;
      return Payment.fromMap(row);
    });
  }
}
