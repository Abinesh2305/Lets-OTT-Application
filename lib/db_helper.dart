import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'movie.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  initDB() async {
    String path = join(await getDatabasesPath(), 'favorites.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY,
            title TEXT,
            overview TEXT,
            posterPath TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertFavorite(Movie movie) async {
    final dbClient = await db;
    await dbClient.insert('favorites', movie.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(int id) async {
    final dbClient = await db;
    await dbClient.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Movie>> getFavorites() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query('favorites');
    return List.generate(maps.length, (i) => Movie.fromJson(maps[i]));
  }

  Future<bool> isFavorite(int id) async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query('favorites', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty;
  }
}
