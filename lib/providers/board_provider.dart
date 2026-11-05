import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../algos/lexorank.dart';
import '../models/board.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';
import '../repositories/board_repository.dart';
import '../services/realtime_service.dart';
import '../utils/copy_with.dart';
import 'boards_provider.dart';
import 'sprint_provider.dart';

/// State for a single board with its columns and cards.
class BoardState {
  final Board board;
  final List<BoardColumn> columns;
  final Map<String, List<model.Card>> columnCards;
  final String? errorMessage;

  const BoardState({
    required this.board,
    this.columns = const [],
    this.columnCards = const {},
    this.errorMessage,
  });

  BoardState copyWith({
    Board? board,
    List<BoardColumn>? columns,
    Map<String, List<model.Card>>? columnCards,
    Object? errorMessage = unset,
  }) {
    return BoardState(
      board: board ?? this.board,
      columns: columns ?? this.columns,
      columnCards: columnCards ?? this.columnCards,
      errorMessage: identical(errorMessage, unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Notifier for managing a single board's state and operations.
class BoardNotifier extends StateNotifier<AsyncValue<BoardState>> {
  final BoardRepository _repository;
  final RealtimeService _realtimeService;
  final String _boardId;
  final Ref _ref;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  BoardNotifier(
    this._repository,
    this._realtimeService,
    this._boardId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    _loadBoard();
    _setupRealtimeListener();
  }

  Future<void> _loadBoard() async {
    state = const AsyncValue.loading();
    try {
      final board = await _repository.getBoard(_boardId);
      final columns = await _repository.getColumnsByBoard(_boardId);
      final cards = await _repository.getCardsByBoard(_boardId);

      final columnCards = <String, List<model.Card>>{
        for (final column in columns) column.id: <model.Card>[],
      };
      for (final card in cards) {
        (columnCards[card.columnId] ??= []).add(card);
      }
      for (final list in columnCards.values) {
        list.sort((a, b) => a.rank.compareTo(b.rank));
      }

      if (!mounted) return;
      state = AsyncValue.data(
        BoardState(board: board, columns: columns, columnCards: columnCards),
      );
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupRealtimeListener() {
    _realtimeSubscription = _realtimeService
        .subscribeToBoardUpdates(_boardId)
        .listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(RealtimeEvent event) async {
    if (!mounted) return;
    final currentState = state.value;
    if (currentState == null) return;

    try {
      switch (event.collection) {
        case 'boards':
          await _handleBoardEvent(event, currentState);
          break;
        case 'columns':
          await _handleColumnEvent(event, currentState);
          break;
        case 'cards':
          await _handleCardEvent(event, currentState);
          break;
      }
    } catch (_) {
      // A malformed event must never take down the board view.
    }
  }

  Future<void> _handleBoardEvent(
    RealtimeEvent event,
    BoardState currentState,
  ) async {
    if (event.type == RealtimeEventType.update && event.data != null) {
      final updatedBoard = Board.fromJson(event.data!);
      state = AsyncValue.data(currentState.copyWith(board: updatedBoard));
    } else if (event.type == RealtimeEventType.delete) {
      state = AsyncValue.error('Board deleted', StackTrace.current);
    }
  }

  Future<void> _handleColumnEvent(
    RealtimeEvent event,
    BoardState currentState,
  ) async {
    final columns = List<BoardColumn>.from(currentState.columns);
    final columnCards = Map<String, List<model.Card>>.from(
      currentState.columnCards,
    );

    switch (event.type) {
      case RealtimeEventType.create:
        if (event.data != null) {
          final newColumn = BoardColumn.fromJson(event.data!);
          if (newColumn.boardId != _boardId) return;
          if (!columns.any((column) => column.id == newColumn.id)) {
            columns.add(newColumn);
            columnCards.putIfAbsent(newColumn.id, () => []);
          }
          columns.sort((a, b) => a.position.compareTo(b.position));
          state = AsyncValue.data(
            currentState.copyWith(columns: columns, columnCards: columnCards),
          );
        }
        break;

      case RealtimeEventType.update:
        if (event.data != null) {
          final updatedColumn = BoardColumn.fromJson(event.data!);
          final index = columns.indexWhere((c) => c.id == updatedColumn.id);
          if (index != -1) {
            columns[index] = updatedColumn;
            columns.sort((a, b) => a.position.compareTo(b.position));
            state = AsyncValue.data(
              currentState.copyWith(columns: columns, columnCards: columnCards),
            );
          }
        }
        break;

      case RealtimeEventType.delete:
        columns.removeWhere((c) => c.id == event.documentId);
        columnCards.remove(event.documentId);
        state = AsyncValue.data(
          currentState.copyWith(columns: columns, columnCards: columnCards),
        );
        break;
    }
  }

  Future<void> _handleCardEvent(
    RealtimeEvent event,
    BoardState currentState,
  ) async {
    final newCardsByColumn = Map<String, List<model.Card>>.from(
      currentState.columnCards.map(
        (key, value) => MapEntry(key, List<model.Card>.from(value)),
      ),
    );

    switch (event.type) {
      case RealtimeEventType.create:
        if (event.data != null) {
          final newCard = model.Card.fromJson(event.data!);
          final cardList = newCardsByColumn[newCard.columnId] ?? [];
          if (!cardList.any((c) => c.id == newCard.id)) {
            cardList.add(newCard);
            cardList.sort((a, b) => a.rank.compareTo(b.rank));
            newCardsByColumn[newCard.columnId] = cardList;
            state = AsyncValue.data(
              currentState.copyWith(columnCards: newCardsByColumn),
            );
          }
        }
        break;

      case RealtimeEventType.update:
        if (event.data != null) {
          final updatedCard = model.Card.fromJson(event.data!);
          newCardsByColumn.forEach((_, cards) {
            cards.removeWhere((c) => c.id == updatedCard.id);
          });
          final targetList = newCardsByColumn[updatedCard.columnId] ?? [];
          targetList.add(updatedCard);
          targetList.sort((a, b) => a.rank.compareTo(b.rank));
          newCardsByColumn[updatedCard.columnId] = targetList;
          state = AsyncValue.data(
            currentState.copyWith(columnCards: newCardsByColumn),
          );
        }
        break;

      case RealtimeEventType.delete:
        final cardId = event.documentId;
        var changed = false;
        for (final entry in newCardsByColumn.entries) {
          final before = entry.value.length;
          entry.value.removeWhere((c) => c.id == cardId);
          changed = changed || entry.value.length != before;
        }
        if (changed) {
          state = AsyncValue.data(
            currentState.copyWith(columnCards: newCardsByColumn),
          );
        }
        break;
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.unsubscribeFromBoard(_boardId);
    super.dispose();
  }

  void _setError(String message) {
    if (!mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(errorMessage: message));
  }

  void clearError() {
    if (!mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(errorMessage: null));
  }

  /// Reloads just the board row (used by dialogs that edit metadata).
  Future<void> refreshBoard() async {
    final currentState = state.value;
    if (currentState == null) return;
    try {
      final board = await _repository.getBoard(_boardId);
      if (!mounted) return;
      state = AsyncValue.data(currentState.copyWith(board: board));
    } catch (_) {
      // Keep the current state; a realtime event will correct it.
    }
  }

  Future<BoardColumn?> createColumn({
    required String name,
    required int color,
    int? wipLimit,
  }) async {
    final currentState = state.value;
    if (currentState == null) return null;

    try {
      final newColumn = BoardColumn(
        id: '',
        boardId: _boardId,
        name: name,
        position: currentState.columns.length,
        color: color,
        wipLimit: wipLimit,
      );
      return await _repository.createColumn(newColumn);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateColumn(BoardColumn column) async {
    try {
      await _repository.updateColumn(column);
    } catch (e) {
      _setError('Failed to update column: $e');
    }
  }

  Future<void> deleteColumn(String columnId) async {
    try {
      await _repository.deleteColumn(columnId);
      _ref.invalidate(boardSprintsProvider(_boardId));
      await _refreshActiveSprint();
    } catch (e) {
      _setError('Failed to delete column: $e');
    }
  }

  Future<void> _refreshActiveSprint() async {
    try {
      await _ref.read(sprintNotifierProvider(_boardId).notifier).refresh();
    } catch (_) {
      // The sprint header will catch up on its next event/load.
    }
  }

  Future<void> deleteCard(String cardId) async {
    final originalState = state.value;
    if (originalState == null) return;

    String? sourceColumnId;
    originalState.columnCards.forEach((colId, cards) {
      if (cards.any((c) => c.id == cardId)) sourceColumnId = colId;
    });
    if (sourceColumnId == null) return;

    final newCardsByColumn = Map<String, List<model.Card>>.from(
      originalState.columnCards,
    );
    final sourceList = List<model.Card>.from(newCardsByColumn[sourceColumnId]!);
    sourceList.removeWhere((c) => c.id == cardId);
    newCardsByColumn[sourceColumnId!] = sourceList;
    state = AsyncValue.data(
      originalState.copyWith(columnCards: newCardsByColumn),
    );

    try {
      await _repository.deleteCard(cardId);
    } catch (e) {
      state = AsyncValue.data(
        originalState.copyWith(errorMessage: 'Failed to delete card: $e'),
      );
    }
  }

  Future<void> updateCard({required model.Card updatedCard}) async {
    final originalState = state.value;
    if (originalState == null) return;

    final columnId = updatedCard.columnId;
    final cardList = List<model.Card>.from(
      originalState.columnCards[columnId] ?? [],
    );
    final cardIndex = cardList.indexWhere((c) => c.id == updatedCard.id);
    if (cardIndex == -1) return;

    final newCardsByColumn = Map<String, List<model.Card>>.from(
      originalState.columnCards,
    );
    newCardsByColumn[columnId] = List<model.Card>.from(cardList)
      ..[cardIndex] = updatedCard;
    state = AsyncValue.data(
      originalState.copyWith(columnCards: newCardsByColumn),
    );

    try {
      await _repository.updateCard(updatedCard);
    } catch (e) {
      state = AsyncValue.data(
        originalState.copyWith(errorMessage: 'Failed to update card: $e'),
      );
    }
  }

  Future<void> moveCard({
    required model.Card card,
    required String targetColumnId,
    required int targetPosition,
  }) async {
    final previousState = state.value;
    if (previousState == null) return;

    final newColumnCards = Map<String, List<model.Card>>.from(
      previousState.columnCards,
    );
    final sourceColumnId = newColumnCards.entries
        .firstWhere(
          (entry) => entry.value.any((c) => c.id == card.id),
          orElse: () => const MapEntry('', []),
        )
        .key;
    if (sourceColumnId.isEmpty) return;

    final sourceCards = List<model.Card>.from(newColumnCards[sourceColumnId]!);
    final originalIndex = sourceCards.indexWhere((c) => c.id == card.id);
    sourceCards.removeWhere((c) => c.id == card.id);

    final targetCards = List<model.Card>.from(
      newColumnCards[targetColumnId] ?? [],
    );
    if (sourceColumnId == targetColumnId) {
      targetCards.removeWhere((c) => c.id == card.id);
    }
    targetCards.sort((a, b) => a.rank.compareTo(b.rank));

    var adjustedPosition = targetPosition;
    if (sourceColumnId == targetColumnId &&
        originalIndex != -1 &&
        targetPosition > originalIndex) {
      adjustedPosition = targetPosition - 1;
    }
    final clampedPosition = adjustedPosition.clamp(0, targetCards.length);

    String newRank;
    try {
      if (targetCards.isEmpty) {
        newRank = LexoRank.middle('', '');
      } else if (clampedPosition == 0) {
        newRank = LexoRank.middle('', targetCards.first.rank);
      } else if (clampedPosition >= targetCards.length) {
        newRank = LexoRank.middle(targetCards.last.rank, '');
      } else {
        newRank = LexoRank.middle(
          targetCards[clampedPosition - 1].rank,
          targetCards[clampedPosition].rank,
        );
      }
    } on RankSpaceExhausted {
      _setError('Card ranks are full. Use "Rebalance Card Ranks" and retry.');
      return;
    }

    final movedCard = card.copyWith(columnId: targetColumnId, rank: newRank);
    newColumnCards[sourceColumnId] = sourceCards;
    targetCards.insert(clampedPosition, movedCard);
    newColumnCards[targetColumnId] = targetCards;
    state = AsyncValue.data(
      previousState.copyWith(columnCards: newColumnCards),
    );

    try {
      await _repository.moveCard(
        cardId: card.id,
        targetColumnId: targetColumnId,
        newRank: newRank,
      );
    } catch (e) {
      state = AsyncValue.data(
        previousState.copyWith(errorMessage: 'Failed to move card: $e'),
      );
    }
  }

  /// Redistributes ranks in a column. Fixes duplicate or exhausted ranks.
  Future<void> rebalanceColumnRanks(String columnId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final cards = List<model.Card>.from(
      currentState.columnCards[columnId] ?? [],
    )..sort((a, b) => a.rank.compareTo(b.rank));
    if (cards.length <= 1) return;

    final ranks = LexoRank.distribute(cards.length);
    try {
      for (var i = 0; i < cards.length; i++) {
        await _repository.moveCard(
          cardId: cards[i].id,
          targetColumnId: columnId,
          newRank: ranks[i],
        );
      }
      await _loadBoard();
    } catch (e) {
      _setError('Failed to rebalance card ranks: $e');
    }
  }

  Future<model.Card?> createCard({
    required String columnId,
    required String title,
    String? description,
    required Priority priority,
  }) async {
    final originalState = state.value;
    if (originalState == null) return null;

    final existingCards = List<model.Card>.from(
      originalState.columnCards[columnId] ?? [],
    )..sort((a, b) => a.rank.compareTo(b.rank));

    String newRank;
    try {
      newRank = existingCards.isEmpty
          ? LexoRank.middle('', '')
          : LexoRank.middle('', existingCards.first.rank);
    } on RankSpaceExhausted {
      _setError('Card ranks are full. Use "Rebalance Card Ranks" and retry.');
      return null;
    }

    final now = DateTime.now();
    final newCardData = model.Card(
      id: '',
      columnId: columnId,
      title: title,
      description: description,
      priority: priority,
      rank: newRank,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final createdCard = await _repository.createCard(newCardData);
      final newCardsByColumn = Map<String, List<model.Card>>.from(
        originalState.columnCards,
      );
      final targetList = List<model.Card>.from(
        newCardsByColumn[columnId] ?? [],
      );
      targetList.insert(0, createdCard);
      newCardsByColumn[columnId] = targetList;
      state = AsyncValue.data(
        originalState.copyWith(columnCards: newCardsByColumn),
      );
      return createdCard;
    } catch (_) {
      return null;
    }
  }
}

/// Provider for a single board. Auto-disposed so leaving a board cancels its
/// realtime subscription and frees its state.
final boardNotifierProvider =
    StateNotifierProvider.family<BoardNotifier, AsyncValue<BoardState>, String>(
      (ref, boardId) {
        final repository = ref.read(boardRepositoryProvider);
        final realtimeService = ref.read(realtimeServiceProvider);
        return BoardNotifier(repository, realtimeService, boardId, ref);
      },
      isAutoDispose: true,
    );
