
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 2;

  // Original Part I table
  static const table = 'my_table';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';

  late Database _db;

  // Open the database
  Future<void> init() async {
    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final path = join(documentsDirectory.path, _databaseName);

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables for a new installation
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');

    await _createCatalogueTables(db);
  }

  // Upgrade the old database without deleting its records
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createCatalogueTables(db);
    }
  }

  // Create folders and cards
  Future<void> _createCatalogueTables(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        suit TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id)
          REFERENCES folders(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_cards_folder_id
      ON cards(folder_id)
    ''');
  }

  // --------------------------------
  // ORIGINAL PART I METHODS
  // --------------------------------

  // Insert a guest
  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  // Get all guests
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table);
  }

  // Count guests
  Future<int> queryRowCount() async {
    final results =
        await _db.rawQuery('SELECT COUNT(*) FROM $table');

    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Update a guest
  Future<int> update(Map<String, dynamic> row) async {
    int id = row[columnId];

    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete a guest
  Future<int> delete(int id) async {
    return await _db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // --------------------------------
  // PART II FOLDER METHODS
  // --------------------------------

  // Create a folder
  Future<int> insertFolder(String name) async {
    final folderName = name.trim();

    if (folderName.isEmpty) {
      throw ArgumentError('Folder name cannot be empty');
    }

    return await _db.insert(
      'folders',
      {
        'name': folderName,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Get folders and card counts
  Future<List<Map<String, dynamic>>> getFoldersWithCounts() async {
    return await _db.rawQuery('''
      SELECT
        folders.id,
        folders.name,
        folders.created_at,
        COUNT(cards.id) AS card_count
      FROM folders
      LEFT JOIN cards
        ON folders.id = cards.folder_id
      GROUP BY
        folders.id,
        folders.name,
        folders.created_at
      ORDER BY folders.name COLLATE NOCASE ASC
    ''');
  }

  // Get all folders
  Future<List<Map<String, dynamic>>> getFolders() async {
    return await _db.query(
      'folders',
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  // Delete a folder and its cards
  Future<int> deleteFolder(int id) async {
    return await _db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --------------------------------
  // PART II CARD METHODS
  // --------------------------------

  // Add a card
  Future<int> insertCard({
    required String title,
    required String suit,
    required int folderId,
    String notes = '',
    String? imageRef,
  }) async {
    final cardTitle = title.trim();

    if (cardTitle.isEmpty) {
      throw ArgumentError('Card title cannot be empty');
    }

    const validSuits = [
      'Hearts',
      'Diamonds',
      'Clubs',
      'Spades',
    ];

    if (!validSuits.contains(suit)) {
      throw ArgumentError('Invalid card suit');
    }

    return await _db.insert(
      'cards',
      {
        'title': cardTitle,
        'suit': suit,
        'notes': notes,
        'image_ref': imageRef?.trim().isEmpty == true
            ? null
            : imageRef,
        'folder_id': folderId,
      },
    );
  }

  // Get cards inside a folder
  Future<List<Map<String, dynamic>>> getCards(
    int folderId,
  ) async {
    return await _db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title COLLATE NOCASE ASC',
    );
  }

  // Update a card using its ID
  Future<int> updateCard({
    required int id,
    required String title,
    required String suit,
    required int folderId,
    String notes = '',
    String? imageRef,
  }) async {
    final cardTitle = title.trim();

    if (cardTitle.isEmpty) {
      throw ArgumentError('Card title cannot be empty');
    }

    const validSuits = [
      'Hearts',
      'Diamonds',
      'Clubs',
      'Spades',
    ];

    if (!validSuits.contains(suit)) {
      throw ArgumentError('Invalid card suit');
    }

    return await _db.update(
      'cards',
      {
        'title': cardTitle,
        'suit': suit,
        'notes': notes,
        'image_ref': imageRef?.trim().isEmpty == true
            ? null
            : imageRef,
        'folder_id': folderId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a card using its ID
  Future<int> deleteCard(int id) async {
    return await _db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --------------------------------
  // DATABASE TESTING METHODS
  // --------------------------------

  // Check database version
  Future<List<Map<String, dynamic>>> getDatabaseVersion() async {
    return await _db.rawQuery('PRAGMA user_version');
  }

  // Check foreign keys
  Future<List<Map<String, dynamic>>> getForeignKeysStatus() async {
    return await _db.rawQuery('PRAGMA foreign_keys');
  }

  // Check the cards relationship
  Future<List<Map<String, dynamic>>> getCardForeignKeys() async {
    return await _db.rawQuery(
      'PRAGMA foreign_key_list(cards)',
    );
  }

  // Check the cards index
  Future<List<Map<String, dynamic>>> getCardIndexes() async {
    return await _db.rawQuery(
      'PRAGMA index_list(cards)',
    );
  }

  // Close database
  Future<void> close() async {
    await _db.close();
  }
}
