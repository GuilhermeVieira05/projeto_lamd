import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalReservation {
  final String id;
  final String serviceTypeName;
  final String providerName;
  final String status;
  final String scheduledAt;
  final String? notes;
  final String createdAt;

  LocalReservation({
    required this.id,
    required this.serviceTypeName,
    required this.providerName,
    required this.status,
    required this.scheduledAt,
    this.notes,
    required this.createdAt,
  });

  factory LocalReservation.fromMap(Map<String, dynamic> map) {
    return LocalReservation(
      id: map['id'] as String,
      serviceTypeName: map['service_type_name'] as String,
      providerName: map['provider_name'] as String,
      status: map['status'] as String,
      scheduledAt: map['scheduled_at'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'service_type_name': serviceTypeName,
    'provider_name': providerName,
    'status': status,
    'scheduled_at': scheduledAt,
    'notes': notes,
    'created_at': createdAt,
  };
}

class LocalDb {
  static Database? _db;

  static Future<Database> _getDb() async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'reservations.db'),
      onCreate: (db, version) => db.execute('''
        CREATE TABLE reservations (
          id TEXT PRIMARY KEY,
          service_type_name TEXT NOT NULL,
          provider_name TEXT NOT NULL,
          status TEXT NOT NULL,
          scheduled_at TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      '''),
      version: 1,
    );
    return _db!;
  }

  static Future<void> saveReservations(List<LocalReservation> reservations) async {
    final db = await _getDb();
    final batch = db.batch();
    batch.delete('reservations');
    for (final r in reservations) {
      batch.insert('reservations', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<LocalReservation>> getReservations() async {
    final db = await _getDb();
    final maps = await db.query('reservations', orderBy: 'created_at DESC');
    return maps.map(LocalReservation.fromMap).toList();
  }

  static Future<void> updateStatus(String id, String status) async {
    final db = await _getDb();
    await db.update('reservations', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }
}
