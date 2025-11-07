import 'package:appwrite/appwrite.dart';
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
  Future<void> archiveBoard(String boardId) async {
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: boardId,
      data: {'archived': true},
    );
  }

  @override
  Future<void> unarchiveBoard(String boardId) async {
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: boardsCollection,
      documentId: boardId,
      data: {'archived': false},
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
    // await tablesDB.updateTransaction(transactionId: tx.$id, commit:true);
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: columnsCollection,
      documentId: columnId,
    );
  }

  @override
  Future<void> reorderColumns(String boardId, List<String> columnIds) async {
    // First, set all positions to a high temporary value to avoid conflicts
    for (int i = 0; i < columnIds.length; i++) {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: columnsCollection,
        documentId: columnIds[i],
        data: {'position': i + 1000}, // Temporary high value
      );
    }

    // Then, set the actual positions
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
      queries: [Query.equal('columnId', columnId), Query.orderAsc('rank')],
    );
    return docs.documents.map((doc) => Card.fromJson(doc.data)).toList();
  }

  @override
  Future<Card> createCard(Card card) async {
    // Since we're using LexoRank for ordering, we don't need to shift positions
    // The rank field will handle the ordering
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: cardsCollection,
      documentId: ID.unique(),
      data: card.toJson(),
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
    required String newRank,
  }) async {
    try {
      // Partial update - only change columnId and rank
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: cardsCollection,
        documentId: cardId,
        data: {'columnId': targetColumnId, 'rank': newRank},
      );
    } catch (e) {
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
