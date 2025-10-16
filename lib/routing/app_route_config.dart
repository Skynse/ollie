/// Route configuration for the entire app
/// Represents the current navigation state
class AppRouteConfig {
  final bool isAuthenticated;
  final bool isLoading;
  final String? selectedProjectId;
  final String? selectedBoardId;
  final String? selectedCardId;
  final bool show404;

  // Home/Auth routes
  AppRouteConfig.loading()
    : isLoading = true,
      isAuthenticated = false,
      selectedProjectId = null,
      selectedBoardId = null,
      selectedCardId = null,
      show404 = false;

  AppRouteConfig.login()
    : isLoading = false,
      isAuthenticated = false,
      selectedProjectId = null,
      selectedBoardId = null,
      selectedCardId = null,
      show404 = false;

  // Projects list (home when authenticated)
  AppRouteConfig.projects()
    : isLoading = false,
      isAuthenticated = true,
      selectedProjectId = null,
      selectedBoardId = null,
      selectedCardId = null,
      show404 = false;

  // Single project boards view
  AppRouteConfig.projectBoards(this.selectedProjectId)
    : isLoading = false,
      isAuthenticated = true,
      selectedBoardId = null,
      selectedCardId = null,
      show404 = false;

  // Board kanban view
  AppRouteConfig.board(this.selectedProjectId, this.selectedBoardId)
    : isLoading = false,
      isAuthenticated = true,
      selectedCardId = null,
      show404 = false;

  // Card details modal/view
  AppRouteConfig.cardDetails(
    this.selectedProjectId,
    this.selectedBoardId,
    this.selectedCardId,
  ) : isLoading = false,
      isAuthenticated = true,
      show404 = false;

  // 404 page
  AppRouteConfig.notFound()
    : isLoading = false,
      isAuthenticated = true,
      selectedProjectId = null,
      selectedBoardId = null,
      selectedCardId = null,
      show404 = true;

  bool get isProjectsPage =>
      isAuthenticated && selectedProjectId == null && !show404;
  bool get isProjectBoardsPage =>
      isAuthenticated &&
      selectedProjectId != null &&
      selectedBoardId == null &&
      !show404;
  bool get isBoardPage =>
      isAuthenticated &&
      selectedProjectId != null &&
      selectedBoardId != null &&
      selectedCardId == null &&
      !show404;
  bool get isCardDetailsPage =>
      isAuthenticated &&
      selectedProjectId != null &&
      selectedBoardId != null &&
      selectedCardId != null &&
      !show404;
}
