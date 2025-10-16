/// Represents ONLY navigation/routing state
/// Separated from business logic
class NavigationState {
  final String? selectedProjectId;
  final String? selectedBoardId;
  final String? selectedCardId;
  final bool show404;

  const NavigationState({
    this.selectedProjectId,
    this.selectedBoardId,
    this.selectedCardId,
    this.show404 = false,
  });

  /// Home/projects page
  const NavigationState.projects()
    : selectedProjectId = null,
      selectedBoardId = null,
      selectedCardId = null,
      show404 = false;

  /// Project boards page
  const NavigationState.projectBoards(this.selectedProjectId)
    : selectedBoardId = null,
      selectedCardId = null,
      show404 = false;

  /// Board kanban view
  const NavigationState.board(this.selectedProjectId, this.selectedBoardId)
    : selectedCardId = null,
      show404 = false;

  /// Card details
  const NavigationState.cardDetails(
    this.selectedProjectId,
    this.selectedBoardId,
    this.selectedCardId,
  ) : show404 = false;

  /// 404 page
  const NavigationState.notFound()
    : selectedProjectId = null,
      selectedBoardId = null,
      selectedCardId = null,
      show404 = true;

  NavigationState copyWith({
    String? selectedProjectId,
    String? selectedBoardId,
    String? selectedCardId,
    bool? show404,
  }) {
    return NavigationState(
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      selectedBoardId: selectedBoardId ?? this.selectedBoardId,
      selectedCardId: selectedCardId ?? this.selectedCardId,
      show404: show404 ?? this.show404,
    );
  }

  // Helper getters
  bool get isProjectsPage => selectedProjectId == null && !show404;
  bool get isProjectBoardsPage =>
      selectedProjectId != null && selectedBoardId == null && !show404;
  bool get isBoardPage =>
      selectedProjectId != null &&
      selectedBoardId != null &&
      selectedCardId == null &&
      !show404;
  bool get isCardDetailsPage =>
      selectedProjectId != null &&
      selectedBoardId != null &&
      selectedCardId != null &&
      !show404;
}
