import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mpos_offline.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS customers');
      await db.execute('DROP TABLE IF EXISTS sync_queue');
      await db.execute('DROP TABLE IF EXISTS store_profile');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Product Catalog Cache
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT,
        sku TEXT,
        barcode TEXT,
        product_code TEXT,
        price REAL,
        stock REAL,
        category TEXT,
        unit_name TEXT,
        is_weighted INTEGER,
        tax_rate REAL,
        discount_rate REAL
      )
    ''');

    // Categories Cache
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');

    // Customers Cache
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY,
        name TEXT,
        phone TEXT,
        credit_limit REAL,
        balance REAL,
        status INTEGER
      )
    ''');

    // Offline Sales Sync Queue
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT,
        payload TEXT,
        created_at TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');
    
    // Store Profile Cache
    await db.execute('''
      CREATE TABLE store_profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        data TEXT
      )
    ''');
  }

  // --- Catalog Operations ---

  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (var product in products) {
        await txn.insert('products', product);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<void> saveCategories(List<String> categories) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('categories');
      for (var name in categories) {
        await txn.insert('categories', {'name': name});
      }
    });
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final res = await db.query('categories');
    return res.map((e) => e['name'] as String).toList();
  }

  Future<void> saveCustomers(List<Map<String, dynamic>> customers) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('customers');
      for (var customer in customers) {
        await txn.insert('customers', customer);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('customers');
  }

  Future<void> saveStoreProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert(
      'store_profile',
      {'id': 1, 'data': jsonEncode(profile)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> getStoreProfile() async {
    final db = await database;
    final res = await db.query('store_profile', where: 'id = ?', whereArgs: [1]);
    if (res.isNotEmpty) {
      return jsonDecode(res.first['data'] as String);
    }
    return {};
  }

  // --- Sync Queue Operations ---

  Future<void> addToQueue(String endpoint, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'endpoint': endpoint,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeFromQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }
}
