
import 'database_helper.dart';
import 'Folder/folder.dart';
import 'Folder/card_record.dart';
class CatalogueRepository {
  final DatabaseHelper db;

  CatalogueRepository(this.db);

  // Get folders with their card counts
  Future<List<Map<String, dynamic>>> getFoldersWithCounts() {
    return db.getFoldersWithCounts();
  }

  // Get typed folders
  Future<List<Folder>> getFolders() async {
    final rows = await db.getFolders();
    return rows.map((row) => Folder.fromMap(row)).toList();
  }

  // Create a folder
  Future<int> addFolder(String name) {
    return db.insertFolder(name);
  }

  // Delete a folder
  Future<int> deleteFolder(int id) {
    return db.deleteFolder(id);
  }

  // Get cards from one folder
  Future<List<CardRecord>> getCards(int folderId) async {
    final rows = await db.getCards(folderId);
    return rows.map((row) => CardRecord.fromMap(row)).toList();
  }

  // Add a card
  Future<int> addCard(CardRecord card) {
    return db.insertCard(
      title: card.title,
      suit: card.suit,
      folderId: card.folderId,
      notes: card.notes,
      imageRef: card.imageRef,
    );
  }

  // Update a card
  Future<int> updateCard(CardRecord card) {
    if (card.id == null) {
      throw ArgumentError('Card ID is required');
    }

    return db.updateCard(
      id: card.id!,
      title: card.title,
      suit: card.suit,
      folderId: card.folderId,
      notes: card.notes,
      imageRef: card.imageRef,
    );
  }

  // Delete a card
  Future<int> deleteCard(int id) {
    return db.deleteCard(id);
  }
}
