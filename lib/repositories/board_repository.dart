import '../models/board.dart';
import '../models/board_column.dart';
import '../models/card.dart';
import '../models/checklist.dart';

/// Persistence interface for the local board data.
abstract class BoardRepository {
  // Board operations
  Future<Board> getBoard(String boardId);
  Future<List<Board>> getAllBoards();
  Future<Board> createBoard(Board board);
  Future<Board> updateBoard(Board board);
  Future<void> deleteBoard(String boardId);
  Future<void> archiveBoard(String boardId);
  Future<void> unarchiveBoard(String boardId);

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
  Future<List<Card>> getCardsByBoard(String boardId);
  Future<Card> createCard(Card card);
  Future<Card> updateCard(Card card);
  Future<void> deleteCard(String cardId);
  Future<void> moveCard({
    required String cardId,
    required String targetColumnId,
    required String newRank,
  });

  // Checklist operations
  Future<Checklist> getChecklist(String checklistId);
  Future<List<Checklist>> getChecklistsByCard(String cardId);
  Future<Checklist> createChecklist(Checklist checklist);
  Future<Checklist> updateChecklist(Checklist checklist);
  Future<void> deleteChecklist(String checklistId);
}
