import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/playing_card.dart';

class CardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // CREATE - Insert a new card
  Future<int> insertCard(PlayingCard card) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('cards', card.toMap());
    } catch (e) {
      throw Exception('Failed to insert card: $e');
    }
  }

  // READ - Get all cards
  Future<List<PlayingCard>> getAllCards() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('cards');
      return maps.map((m) => PlayingCard.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all cards: $e');
    }
  }

  // READ - Get all cards belonging to a specific folder
  Future<List<PlayingCard>> getCardsByFolderId(int folderId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cards',
        where: 'folder_id = ?',
        whereArgs: [folderId],
        orderBy: 'card_name ASC',
      );
      return maps.map((m) => PlayingCard.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cards for folder: $e');
    }
  }

  // READ - Get a single card by ID
  Future<PlayingCard?> getCardById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cards',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return PlayingCard.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to fetch card by id: $e');
    }
  }

  // UPDATE - Update an existing card
  Future<int> updateCard(PlayingCard card) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'cards',
        card.toMap(),
        where: 'id = ?',
        whereArgs: [card.id],
      );
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }

  // DELETE - Remove a single card
  Future<int> deleteCard(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  // Count cards inside a specific folder
  Future<int> getCardCountByFolder(int folderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Move a card to a different folder
  Future<int> moveCardToFolder(int cardId, int newFolderId) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'cards',
        {'folder_id': newFolderId},
        where: 'id = ?',
        whereArgs: [cardId],
      );
    } catch (e) {
      throw Exception('Failed to move card: $e');
    }
  }
}