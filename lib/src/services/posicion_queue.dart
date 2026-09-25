import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PosicionPendiente {
  final int? id;
  final String vendedorId;
  // Tipo de vendedor (PreferenciasUsuario.tipo) -- junto a vendedorId forma
  // la clave compuesta real de dbo.vendedor en el servidor. Nullable porque
  // filas encoladas antes de que este campo existiera no lo tienen.
  final String? vendedorCodigo;
  final double latitud;
  final double longitud;
  final String fechaHora;

  PosicionPendiente({
    this.id,
    required this.vendedorId,
    this.vendedorCodigo,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
  });

  Map<String, Object?> toMap() => {
        'vendedorId': vendedorId,
        'vendedorCodigo': vendedorCodigo,
        'latitud': latitud,
        'longitud': longitud,
        'fechaHora': fechaHora,
      };

  factory PosicionPendiente.fromMap(Map<String, Object?> map) => PosicionPendiente(
        id: map['id'] as int?,
        vendedorId: map['vendedorId'] as String,
        vendedorCodigo: map['vendedorCodigo'] as String?,
        latitud: map['latitud'] as double,
        longitud: map['longitud'] as double,
        fechaHora: map['fechaHora'] as String,
      );
}

/// Cola local (sqlite) de posiciones GPS que no se pudieron enviar al servidor
/// (sin conectividad, timeout, etc.). Se reintenta el envío en cada ciclo del
/// servicio de ubicación en segundo plano, en orden de llegada.
class PosicionQueueDB {
  PosicionQueueDB._();
  static final PosicionQueueDB instance = PosicionQueueDB._();

  static const _maxFilas = 500;

  static Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final opened = await _initDB();
    _database = opened;
    return opened;
  }

  Future<Database> _initDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'PosicionQueue.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE posicion_pendiente (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vendedorId TEXT NOT NULL,
            vendedorCodigo TEXT,
            latitud REAL NOT NULL,
            longitud REAL NOT NULL,
            fechaHora TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE posicion_pendiente ADD COLUMN vendedorCodigo TEXT');
        }
      },
    );
  }

  Future<void> encolar(PosicionPendiente posicion) async {
    final db = await database;
    await db.insert('posicion_pendiente', posicion.toMap());

    // Evita que la cola crezca sin límite si el dispositivo pasa mucho
    // tiempo sin conexión: se descartan los registros más antiguos.
    final total = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM posicion_pendiente'),
        ) ??
        0;
    if (total > _maxFilas) {
      await db.rawDelete(
        'DELETE FROM posicion_pendiente WHERE id IN '
        '(SELECT id FROM posicion_pendiente ORDER BY id ASC LIMIT ?)',
        [total - _maxFilas],
      );
    }
  }

  Future<List<PosicionPendiente>> obtenerPendientes() async {
    final db = await database;
    final resp = await db.query('posicion_pendiente', orderBy: 'id ASC');
    return resp.map((m) => PosicionPendiente.fromMap(m)).toList();
  }

  Future<void> eliminar(int id) async {
    final db = await database;
    await db.delete('posicion_pendiente', where: 'id = ?', whereArgs: [id]);
  }
}
