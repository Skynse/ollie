import '../models/board.dart';
import '../models/board_column.dart';
import '../models/card.dart';
import '../models/label.dart';
import '../models/comment.dart';
import '../models/checklist.dart';

/// Abstract repository interface - backend agnostic
/// Can be implemented for Appwrite, Firebase, REST API, etc.
abstract class BoardRepository {
  // Board operations
  Future<Board> getBoard(String boardId);
  Future<List<Board>> getAllBoards();
  Future<List<Board>> getBoardsByUser(String userId);
  Future<Board> createBoard(Board board);
  Future<Board> updateBoard(Board board);
  Future<void> deleteBoard(String boardId);
  Future<void> archiveBoard(String boardId);
  Future<void> unarchiveBoard(String boardId);
  Future<void> addMember(String boardId, String userId);
  Future<void> removeMember(String boardId, String userId);
  // Column operations
  Future<BoardColumn> getColumn(String columnId);
  Future<List<BoardColumn>> getColumnsByBoard(String boardId);
  Future<BoardColumn> createColumn(BoardColumn column);
  Future<BoardColumn> updateColumn(BoardColumn column);
  Future<void> deleteColumn(String columnId);
  Future<void> reorderColumns(String boardId, List<String> columnIds);

  // Card operations
  Future<Card> getCard(String cardId);
  Future<List<Card>> getCardsByColumn(String columnId);
  Future<Card> createCard(Card card);
  Future<Card> updateCard(Card card);
  Future<void> deleteCard(String cardId);
  Future<void> moveCard({
    required String cardId,
    required String sourceColumnId,
    required String targetColumnId,

    required String newRank,
  });
  Future<void> reorderCards(String columnId, List<String> cardIds);

  // Label operations
  Future<Label> getLabel(String labelId);
  Future<List<Label>> getLabelsByBoard(String boardId);
  Future<Label> createLabel(Label label);
  Future<Label> updateLabel(Label label);
  Future<void> deleteLabel(String labelId);

  // Comment operations
  Future<Comment> getComment(String commentId);
  Future<List<Comment>> getCommentsByCard(String cardId);
  Future<Comment> createComment(Comment comment);
  Future<Comment> updateComment(Comment comment);
  Future<void> deleteComment(String commentId);

  // Checklist operations
  Future<Checklist> getChecklist(String checklistId);
  Future<List<Checklist>> getChecklistsByCard(String cardId);
  Future<Checklist> createChecklist(Checklist checklist);
  Future<Checklist> updateChecklist(Checklist checklist);
  Future<void> deleteChecklist(String checklistId);
}
