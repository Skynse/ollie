import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:ollie/repositories/appwrite/appwrite_config.dart';
import '../../models/board.dart';
import '../../models/board_column.dart';
import '../../models/card.dart';
import '../../models/label.dart';
import '../../models/comment.dart';
import '../../models/checklist.dart';
import '../board_repository.dart';

/// Appwrite implementation of BoardRepository
/// This is the ONLY place that knows about Appwrite
class AppwriteBoardRepository implements BoardRepository {
  final Databases databases;
  final String databaseId;

  AppwriteBoardRepository({required this.databases, required this.databaseId});

  // Collection IDs - configure these in your Appwrite console
  static const String boardsCollection = 'boards';
  static const String columnsCollection = 'columns';
  static const String cardsCollection = 'cards';
  static const String labelsCollection = 'labels';
  static const String commentsCollection = 'comments';
  static const String checklistsCollection = 'checklists';

  // Board operations
  @override
  Future<Board> getBoard(String boardId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: boardId,
    );
    return Board.fromJson(doc.data);
  }

  @override
  Future<List<Board>> getBoardsByUser(String userId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: boardsCollection,
      queries: [Query.equal('members', userId)],
    );

    return docs.documents.map((doc) => Board.fromJson(doc.data)).toList();
  }

  @override
  Future<Board> createBoard(Board board) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: ID.unique(),
      data: board.toJson(),
    );
    return Board.fromJson(doc.data);
  }

  @override
  Future<Board> updateBoard(Board board) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: board.id,
      data: board.toJson(),
    );
    return Board.fromJson(doc.data);
  }

  @override
  Future<void> deleteBoard(String boardId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: boardId,
    );
  }

  @override
  Future<void> addMember(String boardId, String userId) async {
    final board = await getBoard(boardId);
    final updatedMemberIds = [...board.memberIds, userId];
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: boardId,
      data: {'members': updatedMemberIds},
    );
  }

  @override
  Future<void> removeMember(String boardId, String userId) async {
    final board = await getBoard(boardId);
    final updatedMemberIds = board.memberIds
        .where((id) => id != userId)
        .toList();
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: boardId,
      data: {'members': updatedMemberIds},
    );
  }

  // Column operations
  @override
  Future<BoardColumn> getColumn(String columnId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: columnsCollection,
      documentId: columnId,
    );
    return BoardColumn.fromJson(doc.data);
  }

  @override
  Future<List<BoardColumn>> getColumnsByBoard(String boardId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: columnsCollection,
      queries: [Query.equal('boardId', boardId), Query.orderAsc('position')],
    );
    return docs.documents.map((doc) => BoardColumn.fromJson(doc.data)).toList();
  }

  @override
  Future<BoardColumn> createColumn(BoardColumn column) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: columnsCollection,
      documentId: ID.unique(),
      data: column.toJson(),
    );
    return BoardColumn.fromJson(doc.data);
  }

  @override
  Future<BoardColumn> updateColumn(BoardColumn column) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: columnsCollection,
      documentId: column.id,
      data: column.toJson(),
    );
    return BoardColumn.fromJson(doc.data);
  }

  @override
  Future<void> deleteColumn(String columnId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: columnsCollection,
      documentId: columnId,
    );
  }

  @override
  Future<void> reorderColumns(String boardId, List<String> columnIds) async {
    // Update each column's position
    for (int i = 0; i < columnIds.length; i++) {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: columnsCollection,
        documentId: columnIds[i],
        data: {'position': i},
      );
    }
  }

  // Card operations
  @override
  Future<Card> getCard(String cardId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: cardsCollection,
      documentId: cardId,
    );
    return Card.fromJson(doc.data);
  }

  @override
  Future<List<Card>> getCardsByColumn(String columnId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: cardsCollection,
      queries: [Query.equal('columnId', columnId), Query.orderAsc('position')],
    );
    return docs.documents.map((doc) => Card.fromJson(doc.data)).toList();
  }

  @override
  Future<Card> createCard(Card card) async {
    // --- START OF MODIFICATION ---
    // Get all cards in the target column to shift their positions
    final existingCards = await getCardsByColumn(card.columnId);

    // Create a list of futures for batch updating
    final List<Future> updateFutures = [];

    // Shift all existing cards down by one position
    for (final existingCard in existingCards) {
      updateFutures.add(
        databases.updateDocument(
          databaseId: databaseId,
          collectionId: cardsCollection,
          documentId: existingCard.id,
          data: {'position': existingCard.position + 1},
        ),
      );
    }

    // Wait for all shifts to complete
    await Future.wait(updateFutures);

    // Now, create the new card at position 0
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: cardsCollection,
      documentId: ID.unique(),
      data: card.toJson(), // The card already has position: 0 from the notifier
    );

    return Card.fromJson(doc.data);
  }

  @override
  Future<Card> updateCard(Card card) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: cardsCollection,
      documentId: card.id,
      data: card.toJson(),
    );
    return Card.fromJson(doc.data);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: cardsCollection,
      documentId: cardId,
    );
  }

  @override
  Future<void> moveCard({
    required String cardId,
    required String sourceColumnId,
    required String targetColumnId,
    required int targetPosition,
  }) async {
    Transaction? tx; // Use a nullable transaction object for safe rollback
    try {
      // Step 1: Get the current state of cards from both columns.
      final sourceColumnCards = await getCardsByColumn(sourceColumnId);
      final List<Card> targetColumnCards;

      // If reordering in the same column, we work on the same list instance.
      if (sourceColumnId == targetColumnId) {
        targetColumnCards = sourceColumnCards;
      } else {
        targetColumnCards = await getCardsByColumn(targetColumnId);
      }

      // Step 2: Perform the move in-memory to determine the final state.
      final cardToMove = sourceColumnCards.firstWhere((c) => c.id == cardId);
      sourceColumnCards.removeWhere((c) => c.id == cardId);

      final adjustedTargetPosition = targetPosition.clamp(
        0,
        targetColumnCards.length,
      );
      targetColumnCards.insert(adjustedTargetPosition, cardToMove);

      // Step 3: Build the list of database operations based on the changes.
      final List<Map<String, dynamic>> operations = [];

      // Operations for the source column (if different from target)
      if (sourceColumnId != targetColumnId) {
        for (int i = 0; i < sourceColumnCards.length; i++) {
          final card = sourceColumnCards[i];
          if (card.position != i) {
            operations.add({
              'action': 'update',
              'databaseId': databaseId,
              'collectionId': cardsCollection,
              'documentId': card.id,
              'data': {'position': i},
            });
          }
        }
      }

      // Operations for the target column
      for (int i = 0; i < targetColumnCards.length; i++) {
        final card = targetColumnCards[i];
        final newPosition = i;

        Map<String, dynamic> updateData = {};

        // Check if position needs to be updated
        if (card.position != newPosition) {
          updateData['position'] = newPosition;
        }

        // If this is the moved card, check if its columnId needs updating
        if (card.id == cardId && card.columnId != targetColumnId) {
          updateData['columnId'] = targetColumnId;
        }

        // If there's anything to update for this card, add it to operations
        if (updateData.isNotEmpty) {
          operations.add({
            'action': 'update',
            'databaseId': databaseId,
            'collectionId': cardsCollection,
            'documentId': card.id,
            'data': updateData,
          });
        }
      }

      // Step 4: Execute the operations within a transaction if there are any.
      if (operations.isNotEmpty) {
        tx = await databases.createTransaction();

        // Stage all operations in a single request
        await databases.createOperations(
          transactionId: tx.$id,
          operations: operations,
        );

        // Commit the transaction
        await databases.updateTransaction(transactionId: tx.$id, commit: true);
      }
    } catch (e) {
      // If anything fails, roll back the transaction if it was created
      if (tx != null) {
        await databases.updateTransaction(
          transactionId: tx.$id,
          rollback: true,
        );
      }
      print('Error moving card, transaction rolled back: $e');
      rethrow;
    }
  }

  @override
  Future<void> reorderCards(String columnId, List<String> cardIds) async {
    for (int i = 0; i < cardIds.length; i++) {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: cardsCollection,
        documentId: cardIds[i],
        data: {'position': i},
      );
    }
  }

  // Label operations
  @override
  Future<Label> getLabel(String labelId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: labelsCollection,
      documentId: labelId,
    );
    return Label.fromJson(doc.data);
  }

  @override
  Future<List<Label>> getLabelsByBoard(String boardId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: labelsCollection,
      queries: [Query.equal('boardId', boardId)],
    );
    return docs.documents.map((doc) => Label.fromJson(doc.data)).toList();
  }

  @override
  Future<Label> createLabel(Label label) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: labelsCollection,
      documentId: ID.unique(),
      data: label.toJson(),
    );
    return Label.fromJson(doc.data);
  }

  @override
  Future<Label> updateLabel(Label label) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: labelsCollection,
      documentId: label.id,
      data: label.toJson(),
    );
    return Label.fromJson(doc.data);
  }

  @override
  Future<void> deleteLabel(String labelId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: labelsCollection,
      documentId: labelId,
    );
  }

  // Comment operations
  @override
  Future<Comment> getComment(String commentId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: commentsCollection,
      documentId: commentId,
    );
    return Comment.fromJson(doc.data);
  }

  @override
  Future<List<Comment>> getCommentsByCard(String cardId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: commentsCollection,
      queries: [Query.equal('cardId', cardId), Query.orderDesc('\$createdAt')],
    );
    return docs.documents.map((doc) => Comment.fromJson(doc.data)).toList();
  }

  @override
  Future<Comment> createComment(Comment comment) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: commentsCollection,
      documentId: ID.unique(),
      data: comment.toJson(),
    );
    return Comment.fromJson(doc.data);
  }

  @override
  Future<Comment> updateComment(Comment comment) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: commentsCollection,
      documentId: comment.id,
      data: comment.toJson(),
    );
    return Comment.fromJson(doc.data);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: commentsCollection,
      documentId: commentId,
    );
  }

  // Checklist operations
  @override
  Future<Checklist> getChecklist(String checklistId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: checklistsCollection,
      documentId: checklistId,
    );
    return Checklist.fromJson(doc.data);
  }

  @override
  Future<List<Checklist>> getChecklistsByCard(String cardId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: checklistsCollection,
      queries: [Query.equal('cardId', cardId)],
    );
    return docs.documents.map((doc) => Checklist.fromJson(doc.data)).toList();
  }

  @override
  Future<Checklist> createChecklist(Checklist checklist) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: checklistsCollection,
      documentId: ID.unique(),
      data: checklist.toJson(),
    );
    return Checklist.fromJson(doc.data);
  }

  @override
  Future<Checklist> updateChecklist(Checklist checklist) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: checklistsCollection,
      documentId: checklist.id,
      data: checklist.toJson(),
    );
    return Checklist.fromJson(doc.data);
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: checklistsCollection,
      documentId: checklistId,
    );
  }
}
