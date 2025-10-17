import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/sprint.dart';
import '../models/time_log.dart';
import '../repositories/sprint_repository.dart';
import '../repositories/appwrite/appwrite_config.dart';

/// Sprint repository provider
final sprintRepositoryProvider = Provider<SprintRepository>((ref) {
  return AppwriteConfig.createSprintRepository();
});

/// Provider for all sprints in a board
final boardSprintsProvider = FutureProvider.family<List<Sprint>, String>((
  ref,
  boardId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return await repository.getSprintsByBoard(boardId);
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
  final SprintRepository _repository;
  final String _boardId;

  SprintNotifier(this._repository, this._boardId) : super(null) {
    _loadActiveSprint();
  }

  Future<void> _loadActiveSprint() async {
    try {
      final sprint = await _repository.getActiveSprint(_boardId);
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

      final created = await _repository.createSprint(sprint);
      await _loadActiveSprint();
      return created;
    } catch (e) {
      return null;
    }
  }

  /// Start a sprint (change status to active)
  Future<void> startSprint(String sprintId) async {
    if (state == null) return;

    try {
      final current = await _repository.getSprint(sprintId);
      final updated = current.copyWith(status: SprintStatus.active);
      await _repository.updateSprint(updated);
      await _loadActiveSprint();
    } catch (e) {
      // Handle error
    }
  }

  /// Complete a sprint
  Future<void> completeSprint(String sprintId) async {
    try {
      final current = await _repository.getSprint(sprintId);
      final updated = current.copyWith(status: SprintStatus.completed);
      await _repository.updateSprint(updated);
      await _loadActiveSprint();
    } catch (e) {
      // Handle error
    }
  }

  /// Add card to sprint
  Future<void> addCardToSprint(String sprintId, String cardId) async {
    try {
      final sprint = await _repository.getSprint(sprintId);
      final updatedCardIds = [...sprint.cardIds, cardId];
      final updated = sprint.copyWith(cardIds: updatedCardIds);
      await _repository.updateSprint(updated);
      await _loadActiveSprint();
    } catch (e) {
      // Handle error
    }
  }

  /// Remove card from sprint
  Future<void> removeCardFromSprint(String sprintId, String cardId) async {
    try {
      final sprint = await _repository.getSprint(sprintId);
      final updatedCardIds = sprint.cardIds
          .where((id) => id != cardId)
          .toList();
      final updated = sprint.copyWith(cardIds: updatedCardIds);
      await _repository.updateSprint(updated);
      await _loadActiveSprint();
    } catch (e) {
      // Handle error
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
      final existing = await _repository.getActiveTimeLog(userId);
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

      return await _repository.createTimeLog(timeLog);
    } catch (e) {
      rethrow;
    }
  }

  /// Stop a running timer
  Future<TimeLog?> stopTimer(String timeLogId) async {
    try {
      final timeLog = await _repository.getTimeLog(timeLogId);
      final now = DateTime.now();
      final duration = now.difference(timeLog.startTime).inMinutes;

      final updated = timeLog.copyWith(
        endTime: now,
        durationMinutes: duration,
        isActive: false,
        updatedAt: now,
      );

      return await _repository.updateTimeLog(updated);
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
  }) async {
    try {
      final now = DateTime.now();
      final timeLog = TimeLog(
        id: '',
        cardId: cardId,
        userId: userId,
        startTime: now.subtract(Duration(minutes: durationMinutes)),
        endTime: now,
        durationMinutes: durationMinutes,
        notes: notes,
        isActive: false,
        sprintId: sprintId,
        createdAt: now,
        updatedAt: now,
      );

      return await _repository.createTimeLog(timeLog);
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
      final repository = ref.read(sprintRepositoryProvider);
      return SprintNotifier(repository, boardId);
    });
