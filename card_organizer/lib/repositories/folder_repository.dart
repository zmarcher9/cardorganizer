import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';

class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // CREATE - Insert a new folder
  Future<int> insertFolder(Folder folder) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('folders', folder.toMap());
    } catch (e) {
      throw Exception('Failed to insert folder: $e');
    }
  }

  // READ - Get all folders ordered by timestamp
  Future<List<Folder>> getAllFolders() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps =
          await db.query('folders', orderBy: 'timestamp ASC');
      return maps.map((m) => Folder.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to fetch folders: $e');
    }
  }

  // READ - Get a single folder by ID
  Future<Folder?> getFolderById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'folders',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return Folder.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to fetch folder by id: $e');
    }
  }

  // UPDATE - Update an existing folder
  Future<int> updateFolder(Folder folder) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'folders',
        folder.toMap(),
        where: 'id = ?',
        whereArgs: [folder.id],
      );
    } catch (e) {
      throw Exception('Failed to update folder: $e');
    }
  }

  // DELETE - Delete a folder; CASCADE removes its cards automatically
  Future<int> deleteFolder(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }

  // Count total folders
  Future<int> getFolderCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM folders');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}