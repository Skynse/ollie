import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/sprint.dart';
import '../models/time_log.dart';
import '../repositories/local/local_config.dart';
import '../repositories/sprint_repository.dart';

/// Sprint repository provider.
final sprintRepositoryProvider = Provider<SprintRepository>((ref) {
  return LocalConfig.createSprintRepository();
});

/// All sprints in a board.
final boardSprintsProvider = FutureProvider.family<List<Sprint>, String>((
  ref,
  boardId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return repository.getSprintsByBoard(boardId);
}, isAutoDispose: true);

/// A single sprint by ID.
final sprintProvider = FutureProvider.family<Sprint, String>((
  ref,
  sprintId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return repository.getSprint(sprintId);
}, isAutoDispose: true);

/// Time logs for a card.
final cardTimeLogsProvider = FutureProvider.family<List<TimeLog>, String>((
  ref,
  cardId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return repository.getTimeLogsByCard(cardId);
}, isAutoDispose: true);

/// Time logs for a sprint.
final sprintTimeLogsProvider = FutureProvider.family<List<TimeLog>, String>((
  ref,
  sprintId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  return repository.getTimeLogsBySprint(sprintId);
}, isAutoDispose: true);

/// State notifier for the active sprint and sprint operations.
class SprintNotifier extends StateNotifier<Sprint?> {
  final Ref _ref;
  final SprintRepository _sprintRepository;
  final String _boardId;

  SprintNotifier(this._ref, this._sprintRepository, this._boardId)
    : super(null) {
    _loadActiveSprint();
  }

  void _invalidateBoardSprintProviders() {
    _ref.invalidate(boardSprintsProvider(_boardId));
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
      if (!mounted) return;
      state = sprint;
    } catch (_) {
      if (!mounted) return;
      state = null;
    }
  }

  Future<Sprint> createSprint({
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    required double targetHours,
  }) async {
    final now = DateTime.now();
    final sprint = Sprint(
      id: '',
      boardId: _boardId,
      name: name,
      goal: goal,
      startDate: startDate,
      endDate: endDate,
      targetHours: targetHours,
      status: SprintStatus.planning,
      createdAt: now,
      updatedAt: now,
    );

    final created = await _sprintRepository.createSprint(sprint);
    _invalidateBoardSprintProviders();
    await _loadActiveSprint();
    return created;
  }

  /// Starts [sprintId], refusing to run two sprints at once.
  Future<void> startSprint(String sprintId) async {
    final existing = await _sprintRepository.getActiveSprint(_boardId);
    if (existing != null && existing.id != sprintId) {
      throw StateError(
        'Sprint "${existing.name}" is already active. Complete it first.',
      );
    }

    final current = await _sprintRepository.getSprint(sprintId);
    if (current.status == SprintStatus.completed) {
      throw StateError('A completed sprint cannot be restarted.');
    }
    final updated = current.copyWith(status: SprintStatus.active);
    final result = await _sprintRepository.updateSprint(updated);
    state = result;
    _invalidateBoardSprintProviders();
    _invalidateTimeLogProviders(sprintId: sprintId);
    await _loadActiveSprint();
  }

  Future<void> completeSprint(String sprintId) async {
    final current = await _sprintRepository.getSprint(sprintId);
    final updated = current.copyWith(status: SprintStatus.completed);
    await _sprintRepository.updateSprint(updated);
    if (state?.id == sprintId) state = null;
    _invalidateBoardSprintProviders();
    _invalidateTimeLogProviders(sprintId: sprintId);
    await _loadActiveSprint();
  }

  Future<void> addCardToSprint(String sprintId, String cardId) async {
    await _sprintRepository.addCardToSprint(sprintId, cardId);
    _invalidateBoardSprintProviders();
    _invalidateTimeLogProviders(sprintId: sprintId, cardId: cardId);
    await _loadActiveSprint();
  }

  Future<void> removeCardFromSprint(String sprintId, String cardId) async {
    await _sprintRepository.removeCardFromSprint(sprintId, cardId);
    _invalidateBoardSprintProviders();
    _invalidateTimeLogProviders(sprintId: sprintId, cardId: cardId);
    await _loadActiveSprint();
  }

  Future<void> deleteSprint(String sprintId) async {
    await _sprintRepository.deleteSprint(sprintId);
    if (state?.id == sprintId) state = null;
    _invalidateBoardSprintProviders();
    await _loadActiveSprint();
  }

  Future<Sprint> editSprint(Sprint updatedSprint) async {
    final result = await _sprintRepository.updateSprint(updatedSprint);
    if (state?.id == updatedSprint.id) state = result;
    _invalidateBoardSprintProviders();
    _invalidateTimeLogProviders(sprintId: updatedSprint.id);
    return result;
  }

  Future<void> refresh() async => _loadActiveSprint();

  void setActiveSprint(Sprint? sprint) => state = sprint;

  /// Records a completed time log. The repository keeps the card's
  /// `totalLoggedHours` and emits a card update in sync.
  Future<TimeLog> logManualTime({
    required String cardId,
    required int durationMinutes,
    String? notes,
    String? sprintId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final now = DateTime.now();
    final actualStart =
        startTime ?? now.subtract(Duration(minutes: durationMinutes));
    final actualEnd = endTime ?? now;

    final timeLog = TimeLog(
      id: '',
      cardId: cardId,
      startTime: actualStart,
      endTime: actualEnd,
      durationMinutes: durationMinutes,
      notes: notes,
      isActive: false,
      sprintId: sprintId,
      createdAt: now,
      updatedAt: now,
    );

    final created = await _sprintRepository.createTimeLog(timeLog);
    _invalidateTimeLogProviders(sprintId: sprintId, cardId: cardId);
    return created;
  }

  Future<TimeLog> updateTimeLog(TimeLog timeLog) async {
    final updated = await _sprintRepository.updateTimeLog(timeLog);
    _invalidateTimeLogProviders(
      sprintId: updated.sprintId,
      cardId: updated.cardId,
    );
    return updated;
  }

  Future<void> deleteTimeLog(TimeLog timeLog) async {
    await _sprintRepository.deleteTimeLog(timeLog.id);
    _invalidateTimeLogProviders(
      sprintId: timeLog.sprintId,
      cardId: timeLog.cardId,
    );
  }
}

/// Provider for the active sprint notifier.
final sprintNotifierProvider =
    StateNotifierProvider.family<SprintNotifier, Sprint?, String>((
      ref,
      boardId,
    ) {
      final sprintRepository = ref.read(sprintRepositoryProvider);
      return SprintNotifier(ref, sprintRepository, boardId);
    }, isAutoDispose: true);
