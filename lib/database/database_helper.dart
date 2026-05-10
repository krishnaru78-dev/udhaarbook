import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('udhaarbook.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');
  }

  // ─── CUSTOMER OPERATIONS ───────────────────────────────

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final result = await db.query(
      'customers',
      orderBy: 'name ASC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerByName(String name) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
    );
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int customerId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  // ─── TRANSACTION OPERATIONS ────────────────────────────

  Future<int> insertTransaction(UdhaarTransaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<UdhaarTransaction>> getTransactionsByCustomer(
      int customerId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return result.map((map) => UdhaarTransaction.fromMap(map)).toList();
  }

  Future<double> getPendingAmount(int customerId) async {
    final db = await database;

    final udhaarResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE customer_id = ? AND type = ?',
      [customerId, 'udhaar'],
    );
    final paymentResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE customer_id = ? AND type = ?',
      [customerId, 'payment'],
    );

    final totalUdhaar =
        (udhaarResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalPayment =
        (paymentResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return totalUdhaar - totalPayment;
  }

  Future<double> getTotalPendingAllCustomers() async {
    final db = await database;

    final udhaarResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      ['udhaar'],
    );
    final paymentResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      ['payment'],
    );

    final totalUdhaar =
        (udhaarResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalPayment =
        (paymentResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return totalUdhaar - totalPayment;
  }

  Future<String?> getLastTransactionDate(int customerId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['date'] as String?;
  }

  // ─── EXPORT ALL DATA ───────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllDataForExport() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.name as customer_name,
        c.phone as phone,
        t.type as type,
        t.amount as amount,
        t.note as note,
        t.date as date
      FROM transactions t
      JOIN customers c ON t.customer_id = c.id
      ORDER BY c.name, t.date
    ''');
  }

  // ─── CLEAR ALL DATA ────────────────────────────────────

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('customers');
  }

  Future<void> closeDB() async {
    final db = await database;
    db.close();
  }
}