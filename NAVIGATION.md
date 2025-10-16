# Navigator 2.0 Implementation Guide

## Overview

Ollie uses Flutter's **Navigator 2.0** (declarative navigation) instead of go_router. This gives you full control over the navigation stack and supports deep linking, browser back/forward buttons, and URL updates.

## Architecture

```
┌──────────────────────────────────────┐
│  AppRouteConfig                      │  ← Route state definition
├──────────────────────────────────────┤
│  AppRouterDelegate                   │  ← Navigation logic
├──────────────────────────────────────┤
│  AppRouteInformationParser           │  ← URL parsing
└──────────────────────────────────────┘
```

## File Structure

```
lib/routing/
├── app_route_config.dart          # Route state definitions
├── app_router_delegate.dart       # Navigation management
└── app_route_information_parser.dart  # URL parsing
```

## URL Structure

```
/                                  → Projects list (when authenticated)
/login                            → Login screen
/projects                         → Projects list
/projects/:projectId              → Project boards
/projects/:projectId/boards/:boardId     → Kanban board view
/projects/:projectId/boards/:boardId/cards/:cardId  → Card details
```

## How to Navigate in Your UI

### Get the Router Delegate

```dart
// In any widget
final router = Router.of(context).routerDelegate as AppRouterDelegate;
```

### Navigate to Different Screens

```dart
// Show projects list
router.showProjects();

// Show project boards
router.showProjectBoards('project-123');

// Show board kanban view
router.showBoard('project-123', 'board-456');

// Show card details
router.showCardDetails('project-123', 'board-456', 'card-789');

// Close card details (go back to board)
router.closeCardDetails();

// Handle login/logout
router.login();
router.logout();
```

### Example: Navigate from Button

```dart
OllieButton(
  text: 'View Board',
  onPressed: () {
    final router = Router.of(context).routerDelegate as AppRouterDelegate;
    router.showBoard(projectId, boardId);
  },
)
```

### Example: Navigate from List Item

```dart
ListTile(
  title: Text(project.name),
  onTap: () {
    final router = Router.of(context).routerDelegate as AppRouterDelegate;
    router.showProjectBoards(project.id);
  },
)
```

## How Back Navigation Works

Navigator 2.0 automatically handles:
- **Hardware back button** (Android)
- **Browser back button** (Web)
- **Swipe back gesture** (iOS)

The back stack is managed in `AppRouterDelegate.onPopPage`:

```
Card Details → Board → Project Boards → Projects List
```

## Deep Linking

Deep links automatically work! Users can:

```dart
// Open app with URL
https://yourapp.com/projects/abc123/boards/def456

// The app will:
1. Parse URL in AppRouteInformationParser
2. Create AppRouteConfig
3. Update RouterDelegate state
4. Show the correct screen
```

## Authentication Flow

```dart
// On app start (main.dart)
_checkAuthStatus() {
  try {
    await account.get();
    router.login();  // User is authenticated
  } catch (e) {
    router.finishLoading();  // Show login screen
  }
}

// After successful login
router.login();  // Automatically shows projects

// On logout
router.logout();  // Automatically shows login
```

## Replace Placeholder Screens

In `app_router_delegate.dart`, replace placeholders with your actual screens:

```dart
// Before
if (!_isLoading && !_isAuthenticated)
  const MaterialPage(
    child: Placeholder(),  // ❌ Placeholder
  ),

// After
if (!_isLoading && !_isAuthenticated)
  MaterialPage(
    child: LoginScreen(  // ✅ Your screen
      account: account,
      onLogin: () => login(),
    ),
  ),
```

### Screens to Create:

1. **LoginScreen** - Email/password authentication
2. **ProjectsListScreen** - Show all projects
3. **ProjectBoardsScreen** - Show boards in a project
4. **BoardScreen** - Kanban board with columns and cards
5. **CardDetailsScreen** - Full card details modal

## Getting Current Route Info

```dart
// Access router state anywhere
final router = Router.of(context).routerDelegate as AppRouterDelegate;

// Check current route
if (router.selectedBoardId != null) {
  print('Currently viewing board: ${router.selectedBoardId}');
}

// Check auth status
if (router.isAuthenticated) {
  // User is logged in
}
```

## Benefits Over go_router

✅ **Full control** - You own the navigation logic  
✅ **No package dependency** - Pure Flutter  
✅ **Type safe** - No string-based routes  
✅ **Declarative** - Navigation state drives UI  
✅ **Deep linking** - Built-in support  
✅ **Browser support** - URL updates automatically  
✅ **Testable** - Easy to mock RouterDelegate  

## Advanced: Passing Data Between Screens

Instead of route parameters, use the router state:

```dart
// In BoardScreen, get the board ID from router
final router = Router.of(context).routerDelegate as AppRouterDelegate;
final boardId = router.selectedBoardId!;

// Load board data
final board = await boardRepo.getBoard(boardId);
```

## Advanced: Nested Navigation

For tabs within a screen, use a separate Navigator:

```dart
class BoardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        pages: [/* nested pages */],
        onPopPage: (route, result) => route.didPop(result),
      ),
    );
  }
}
```

## Advanced: Modal Routes

Card details uses `fullscreenDialog: true`:

```dart
if (_selectedCardId != null)
  MaterialPage(
    child: CardDetailsScreen(),
    fullscreenDialog: true,  // Shows as modal on iOS
  ),
```

## Debugging

Print current navigation state:

```dart
print('Route config: ${router.currentConfiguration}');
print('Is authenticated: ${router.isAuthenticated}');
print('Selected project: ${router.selectedProjectId}');
```

## Common Patterns

### Navigate and Refresh

```dart
// Create new board and navigate to it
final newBoard = await boardRepo.createBoard(board);
router.showBoard(projectId, newBoard.id);
```

### Navigate Back

```dart
// Pop current screen
Navigator.of(context).pop();

// Or use router methods
router.closeCardDetails();
```

### Conditional Navigation

```dart
if (user.hasPermission) {
  router.showBoard(projectId, boardId);
} else {
  showDialog(...); // Show error
}
```

## Migration from go_router

Before:
```dart
context.go('/projects/$projectId/boards/$boardId');
```

After:
```dart
final router = Router.of(context).routerDelegate as AppRouterDelegate;
router.showBoard(projectId, boardId);
```

## Testing

Mock the router delegate:

```dart
class MockAppRouterDelegate extends AppRouterDelegate {
  @override
  void showBoard(String projectId, String boardId) {
    // Track calls for assertions
  }
}
```

---

**Ready to navigate!** 🚀

Your app now has professional-grade declarative navigation with Navigator 2.0.
