import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'card_organizer.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  // Enable foreign key support (required for ON DELETE CASCADE)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE folders (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp   TEXT NOT NULL
      )
    ''');

    // Create cards table with foreign key linking to folders
    await db.execute('''
      CREATE TABLE cards (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name  TEXT NOT NULL,
        suit       TEXT NOT NULL,
        image_url  TEXT,
        folder_id  INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');

    // Pre-populate with 4 suit folders and 52 cards
    await _prepopulateData(db);
  }

  Future<void> _prepopulateData(Database db) async {
    // Maps suit name to the single-letter code used by the Deck of Cards API
    const suitCode = {
      'Hearts':   'H',
      'Diamonds': 'D',
      'Clubs':    'C',
      'Spades':   'S',
    };

    // Number cards (2-10) use the number itself; face cards have letter codes
    const valueCode = {
      'Ace':   'A',
      'Jack':  'J',
      'Queen': 'Q',
      'King':  'K',
    };

    const cardNames = [
      'Ace', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    for (final suit in suitCode.keys) {
      final folderId = await db.insert('folders', {
        'folder_name': suit,
        'timestamp': DateTime.now().toIso8601String(),
      });

      for (final cardName in cardNames) {
        // Build the two-character code, e.g. "AH", "10C", "KD"
        final code = (valueCode[cardName] ?? cardName) + suitCode[suit]!;
        final imageUrl = 'https://deckofcardsapi.com/static/img/$code.png';

        await db.insert('cards', {
          'card_name': cardName,
          'suit':      suit,
          'image_url': imageUrl,
          'folder_id': folderId,
        });
      }
    }
  }

  // Debug helper: prints all database contents to console
  Future<void> printDatabaseContents() async {
    final db = await database;

    print('=== FOLDERS ===');
    final folders = await db.query('folders');
    for (var folder in folders) {
      print(folder);
    }

    print('\n=== CARDS ===');
    final cards = await db.query('cards');
    for (var card in cards) {
      print(card);
    }

    print('\n=== CARD COUNT BY FOLDER ===');
    final counts = await db.rawQuery(
      'SELECT f.folder_name, COUNT(c.id) as card_count '
      'FROM folders f LEFT JOIN cards c ON f.id = c.folder_id '
      'GROUP BY f.id',
    );
    for (var count in counts) {
      print(count);
    }
  }
}