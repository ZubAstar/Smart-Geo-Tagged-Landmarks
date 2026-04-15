// lib/data/datasources/local_database.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../models/landmark_model.dart';
import '../models/visit_model.dart';

class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _db;

  LocalDatabase._();

  factory LocalDatabase() {
    _instance ??= LocalDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableLandmarks} (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        image TEXT,
        score REAL DEFAULT 0,
        visit_count INTEGER DEFAULT 0,
        avg_distance REAL DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        cached_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableVisitQueue} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        landmark_id INTEGER NOT NULL,
        user_lat REAL NOT NULL,
        user_lon REAL NOT NULL,
        queued_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableVisitHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        landmark_id INTEGER NOT NULL,
        landmark_name TEXT NOT NULL,
        visit_time INTEGER NOT NULL,
        distance REAL DEFAULT 0,
        synced INTEGER DEFAULT 0,
        user_lat REAL,
        user_lon REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE ${AppConstants.tableLandmarks} ADD COLUMN cached_at INTEGER NOT NULL DEFAULT 0');
    }
  }

  // ─── Landmarks ────────────────────────────────────────────────────────────

  Future<void> cacheLandmarks(List<LandmarkModel> landmarks) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final l in landmarks) {
      batch.insert(
        AppConstants.tableLandmarks,
        {...l.toDb(), 'cached_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<LandmarkModel>> getCachedLandmarks() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableLandmarks,
      orderBy: 'score DESC',
    );
    return rows.map((r) => LandmarkModel.fromDb(r)).toList();
  }

  Future<void> softDeleteLandmark(int id) async {
    final db = await database;
    await db.update(
      AppConstants.tableLandmarks,
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreLandmark(int id) async {
    final db = await database;
    await db.update(
      AppConstants.tableLandmarks,
      {'is_deleted': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Visit Queue ──────────────────────────────────────────────────────────

  Future<void> enqueueVisit(QueuedVisit visit) async {
    final db = await database;
    await db.insert(AppConstants.tableVisitQueue, visit.toDb());
  }

  Future<List<QueuedVisit>> getPendingVisits() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableVisitQueue,
      orderBy: 'queued_at ASC',
    );
    return rows.map((r) => QueuedVisit.fromDb(r)).toList();
  }

  Future<void> removeQueuedVisit(int dbId) async {
    final db = await database;
    await db.delete(
      AppConstants.tableVisitQueue,
      where: 'id = ?',
      whereArgs: [dbId],
    );
  }

  Future<int> getPendingVisitCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppConstants.tableVisitQueue}');
    return result.first['cnt'] as int;
  }

  // ─── Visit History ────────────────────────────────────────────────────────

  Future<void> saveVisitHistory(VisitModel visit) async {
    final db = await database;
    await db.insert(
      AppConstants.tableVisitHistory,
      visit.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VisitModel>> getVisitHistory() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableVisitHistory,
      orderBy: 'visit_time DESC',
    );
    return rows.map((r) => VisitModel.fromDb(r)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
