import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _db;
  static const String _dbName = 'taweqa_offline.db';
  static const int _dbVersion = 1;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath${dbPath.endsWith('/') ? '' : '/'}$_dbName';
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profiles (
        id TEXT PRIMARY KEY,
        full_name TEXT,
        phone TEXT,
        email TEXT,
        role TEXT,
        avatar_url TEXT,
        rating REAL,
        banned INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS drivers (
        id TEXT PRIMARY KEY,
        is_available INTEGER DEFAULT 0,
        driver_type TEXT,
        car_model TEXT,
        car_plate TEXT,
        car_color TEXT,
        current_lat REAL,
        current_lng REAL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
        id TEXT PRIMARY KEY,
        driver_id TEXT,
        passenger_id TEXT,
        start_lat REAL,
        start_lng REAL,
        end_lat REAL,
        end_lng REAL,
        distance_km REAL,
        duration_min REAL,
        fare REAL,
        driver_cut REAL,
        status TEXT,
        trip_type TEXT DEFAULT 'instant',
        scheduled_at TEXT,
        share_code TEXT,
        created_at TEXT,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ride_requests (
        id TEXT PRIMARY KEY,
        passenger_id TEXT,
        driver_id TEXT,
        pickup_lat REAL,
        pickup_lng REAL,
        pickup_address TEXT,
        dest_lat REAL,
        dest_lng REAL,
        dest_address TEXT,
        status TEXT,
        estimated_fare REAL,
        estimated_distance REAL,
        estimated_duration REAL,
        scheduled_at TEXT,
        rating REAL,
        review TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS trip_passengers (
        id TEXT PRIMARY KEY,
        trip_id TEXT,
        passenger_id TEXT,
        passenger_name TEXT,
        passenger_phone TEXT,
        pickup_lat REAL,
        pickup_lng REAL,
        pickup_address TEXT,
        dropoff_lat REAL,
        dropoff_lng REAL,
        dropoff_address TEXT,
        status TEXT DEFAULT 'pending',
        fare REAL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallet_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        type TEXT,
        amount REAL,
        balance_before REAL,
        balance_after REAL,
        description TEXT,
        status TEXT,
        paymob_ref TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_categories (
        id TEXT PRIMARY KEY,
        category_name TEXT,
        base_fare REAL,
        per_km_price REAL,
        per_minute_price REAL,
        per_wait_minute REAL,
        created_at TEXT
      )
    ''');
  }

  // ── Generic helpers ──

  static Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> update(String table, Map<String, dynamic> row, String id) async {
    final db = await database;
    return db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> delete(String table, String id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  static Future<Map<String, dynamic>?> get(String table, String id) async {
    final db = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  // ── Sync queue ──

  static Future<void> addToSyncQueue(String tableName, String operation, String recordId, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'operation': operation,
      'record_id': recordId,
      'payload': _encode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'created_at ASC', limit: 50);
  }

  static Future<void> removeSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  static String _encode(Map<String, dynamic> data) {
    return jsonEncode(data);
  }
}
