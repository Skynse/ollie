import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/sprint.dart';
import '../models/time_log.dart';
import '../repositories/sprint_repository.dart';
import '../repositories/board_repository.dart';
import '../repositories/local/local_config.dart';

/// Local timer state (only committed to DB when stopped)
class LocalTimerState {
  final String cardId;
  final String userId;
  final String? sprintId;
  final DateTime startTime;

  LocalTimerState({
    required this.cardId,
    required this.userId,
    this.sprintId,
    required this.startTime,
  });
}

/// Provider for local timer state (not persisted until stopped)
final localTimerProvider = StateProvider<LocalTimerState?>((ref) => null);

/// Sprint repository provider
final sprintRepositoryProvider = Provider<SprintRepository>((ref) {
  return LocalConfig.createSprintRepository();
});

/// Provider for all sprints in a board
final boardSprintsProvider = FutureProvider.family<List<Sprint>, String>((
  ref,
  boardId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return await repository.getSprintsByBoard(boardId);
});

/// Provider for a single sprint by ID
final sprintProvider = FutureProvider.family<Sprint, String>((
  ref,
  sprintId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return await repository.getSprint(sprintId);
});

/// Provider for active sprint in a board
final activeSprintProvider = FutureProvider.family<Sprint?, String>((
  ref,
  boardId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return await repository.getActiveSprint(boardId);
});

/// Provider for time logs by card
final cardTimeLogsProvider = FutureProvider.family<List<TimeLog>, String>((
  ref,
  cardId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return await repository.getTimeLogsByCard(cardId);
});

/// Provider for time logs by sprint
final sprintTimeLogsProvider = FutureProvider.family<List<TimeLog>, String>((
  ref,
  sprintId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return await repository.getTimeLogsBySprint(sprintId);
});

/// Provider for active time log for current user
final activeTimeLogProvider = FutureProvider.family<TimeLog?, String>((
  ref,
  userId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return await repository.getActiveTimeLog(userId);
});

/// Sprint state notifier for managing sprint operations
class SprintNotifier extends StateNotifier<Sprint?> {
  final Ref _ref;
  final SprintRepository _sprintRepository;
  final BoardRepository _boardRepository;
  final String _boardId;

  SprintNotifier(
    this._ref,
    this._sprintRepository,
    this._boardRepository,
    this._boardId,
  ) : super(null) {
    _loadActiveSprint();
  }

  void _invalidateBoardSprintProviders() {
    _ref.invalidate(boardSprintsProvider(_boardId));
    _ref.invalidate(activeSprintProvider(_boardId));
  }

  void _invalidateTimeLogProviders({String? sprintId, String? cardId}) {
    if (cardId != null) {
      _ref.invalidate(cardTimeLogsProvider(cardId));
    }
    if (sprintId != null && sprintId.isNotEmpty) {
      _ref.invalidate(sprintProvider(sprintId));
      _ref.invalidate(sprintTimeLogsProvider(sprintId));
    }
  }

  Future<void> _loadActiveSprint() async {
    try {
      final sprint = await _sprintRepository.getActiveSprint(_boardId);
      state = sprint;
    } catch (e) {
      // Keep state as null on error
      state = null;
    }
  }

  /// Create a new sprint
  Future<Sprint?> createSprint({
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    required double targetHours,
  }) async {
    try {
      final sprint = Sprint(
        id: '',
        boardId: _boardId,
        name: name,
        goal: goal,
        startDate: startDate,
        endDate: endDate,
        targetHours: targetHours,
        status: SprintStatus.planning,
        cardIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _sprintRepository.createSprint(sprint);
      _invalidateBoardSprintProviders();
      await _loadActiveSprint();
      return created;
    } catch (e) {
      return null;
    }
  }

  /// Start a sprint (change status to active)
  Future<void> startSprint(String sprintId) async {
    try {
      final current = await _sprintRepository.getSprint(sprintId);
      final updated = current.copyWith(status: SprintStatus.active);
      final result = await _sprintRepository.updateSprint(updated);
      state = result; // Immediately update state
      _invalidateBoardSprintProviders();
      _invalidateTimeLogProviders(sprintId: sprintId);
      await _loadActiveSprint(); // Also refresh from DB
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Complete a sprint
  Future<void> completeSprint(String sprintId) async {
    try {
      final current = await _sprintRepository.getSprint(sprintId);
      final updated = current.copyWith(status: SprintStatus.completed);
      await _sprintRepository.updateSprint(updated);
      _invalidateBoardSprintProviders();
      _invalidateTimeLogProviders(sprintId: sprintId);
      await _loadActiveSprint();
    } catch (e) {
      // Handle error
    }
  }

  /// Add card to sprint
  Future<void> addCardToSprint(String sprintId, String cardId) async {
    try {
      final sprint = await _sprintRepository.getSprint(sprintId);
      final updatedCardIds = [...sprint.cardIds, cardId];
      final updated = sprint.copyWith(cardIds: updatedCardIds);
      await _sprintRepository.updateSprint(updated);
      _invalidateBoardSprintProviders();
      _invalidateTimeLogProviders(sprintId: sprintId, cardId: cardId);
      await _loadActiveSprint();
    } catch (e) {
      // Handle error
    }
  }

  /// Remove card from sprint
  Future<void> removeCardFromSprint(String sprintId, String cardId) async {
    try {
      final sprint = await _sprintRepository.getSprint(sprintId);
      final updatedCardIds = sprint.cardIds
          .where((id) => id != cardId)
          .toList();
      final updated = sprint.copyWith(cardIds: updatedCardIds);
      await _sprintRepository.updateSprint(updated);
      _invalidateBoardSprintProviders();
      _invalidateTimeLogProviders(sprintId: sprintId, cardId: cardId);
      await _loadActiveSprint();
    } catch (e) {
      // Handle error
    }
  }

  /// Delete a sprint and update the UI immediately
  Future<void> deleteSprint(String sprintId) async {
    try {
      await _sprintRepository.deleteSprint(sprintId);
      if (state?.id == sprintId) {
        state = null;
      }
      _invalidateBoardSprintProviders();
    } catch (e) {
      rethrow;
    }
  }

  /// Update editable sprint details (name, goal, dates, targetHours)
  Future<Sprint?> editSprint(Sprint updatedSprint) async {
    try {
      final result = await _sprintRepository.updateSprint(updatedSprint);
      if (state?.id == updatedSprint.id) {
        state = result;
      }
      _invalidateBoardSprintProviders();
      _invalidateTimeLogProviders(sprintId: updatedSprint.id);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh sprint data (reload active sprint from backend)
  Future<void> refresh() async {
    await _loadActiveSprint();
  }

  /// Manually set the active sprint state (for immediate UI updates)
  void setActiveSprint(Sprint? sprint) {
    state = sprint;
  }

  /// Start a timer for a card
  Future<TimeLog?> startTimer({
    required String cardId,
    required String userId,
    String? sprintId,
  }) async {
    try {
      // Check if user already has an active timer
      final existing = await _sprintRepository.getActiveTimeLog(userId);
      if (existing != null) {
        throw Exception('User already has an active timer');
      }

      final timeLog = TimeLog(
        id: '',
        cardId: cardId,
        userId: userId,
        startTime: DateTime.now(),
        endTime: null,
        durationMinutes: 0,
        notes: null,
        isActive: true,
        sprintId: sprintId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _sprintRepository.createTimeLog(timeLog);
    } catch (e) {
      rethrow;
    }
  }

  /// Stop a running timer
  Future<TimeLog?> stopTimer(String timeLogId) async {
    try {
      final timeLog = await _sprintRepository.getTimeLog(timeLogId);
      final now = DateTime.now();
      final duration = now.difference(timeLog.startTime).inMinutes;

      final updated = timeLog.copyWith(
        endTime: now,
        durationMinutes: duration,
        isActive: false,
        updatedAt: now,
      );

      final stoppedLog = await _sprintRepository.updateTimeLog(updated);
      _invalidateTimeLogProviders(
        sprintId: stoppedLog.sprintId,
        cardId: stoppedLog.cardId,
      );
      return stoppedLog;
    } catch (e) {
      rethrow;
    }
  }

  /// Log time manually
  Future<TimeLog?> logManualTime({
    required String cardId,
    required String userId,
    required int durationMinutes,
    String? notes,
    String? sprintId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final now = DateTime.now();

      // Use provided times or calculate defaults
      final actualStartTime =
          startTime ?? now.subtract(Duration(minutes: durationMinutes));
      final actualEndTime = endTime ?? now;

      final timeLog = TimeLog(
        id: '',
        cardId: cardId,
        userId: userId,
        startTime: actualStartTime,
        endTime: actualEndTime,
        durationMinutes: durationMinutes,
        notes: notes,
        isActive: false,
        sprintId: sprintId,
        createdAt: now,
        updatedAt: now,
      );

      final createdLog = await _sprintRepository.createTimeLog(timeLog);

      // Update card's totalLoggedHours
      try {
        final card = await _boardRepository.getCard(cardId);
        final durationHours = durationMinutes / 60.0;
        final updatedCard = card.copyWith(
          totalLoggedHours: card.totalLoggedHours + durationHours,
        );
        await _boardRepository.updateCard(updatedCard);
      } catch (e) {
        // Log error but don't fail the time log creation
      }

      _invalidateTimeLogProviders(sprintId: sprintId, cardId: cardId);
      return createdLog;
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for sprint notifier
final sprintNotifierProvider =
    StateNotifierProvider.family<SprintNotifier, Sprint?, String>((
      ref,
      boardId,
    ) {
      final sprintRepository = ref.read(sprintRepositoryProvider);
      final boardRepository = LocalConfig.createBoardRepository();
      return SprintNotifier(ref, sprintRepository, boardRepository, boardId);
    });
