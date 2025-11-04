# Cursor Tracking Implementation Analysis
## Ollie Kanban Board - Flutter/Appwrite

---

## Executive Summary

This document provides a comprehensive analysis of the current Appwrite integration in the Ollie kanban board application and identifies the key files where cursor tracking functionality should be implemented.

**Current State:** The app has a robust real-time event system using Appwrite's Realtime API, state management via Flutter Riverpod, and clear separation of concerns with repositories and providers.

**Key Finding:** The architecture is well-suited for cursor tracking. We can leverage the existing real-time service and board state management to add collaborative cursor tracking with minimal friction.

---

## 1. Current Appwrite Integration

### 1.1 Appwrite Configuration

**File:** `C:\Users\austi\projects\ollie\lib\repositories\appwrite\appwrite_config.dart`

**Current Setup:**
- Endpoint: `https://sfo.cloud.appwrite.io/v1`
- Project ID: `68f0a62200038266c6c3`
- Database ID: `68f0c0100009393371fd`
- Client initialized once in `main.dart` via `AppwriteConfig.init()`
- Static access to: `Account`, `Databases`, and `Client` instances

**Collections Currently Used:**
- `boards` - Board metadata and member lists
- `columns` - Column definitions with WIP limits
- `cards` - Individual tasks/cards
- `labels` - Card labels
- `comments` - Card comments
- `checklists` - Card checklist items

**Environment Variables:**
```dart
class Environment {
  static const String appwriteProjectId = '68f0a62200038266c6c3';
  static const String appwriteProjectName = 'ollie';
  static const String appwritePublicEndpoint = 'https://sfo.cloud.appwrite.io/v1';
}
```

### 1.2 Appwrite Providers

**File:** `C:\Users\austi\projects\ollie\lib\providers\appwrite_providers.dart`

Provides Riverpod-based access to:
- `appwriteClientProvider` - Singleton Client instance
- `appwriteAccountProvider` - Account service
- `appwriteDatabasesProvider` - Databases service

---

## 2. Real-time Features Currently Implemented

### 2.1 RealtimeService

**File:** `C:\Users\austi\projects\ollie\lib\services\realtime_service.dart`

**Current Real-time Subscriptions:**
1. **Board Updates** - Watches: `boards.{boardId}`, `columns.*`, `cards.*`
2. **Column Updates** - Watches: `columns.{columnId}`, `cards.*`
3. **Card Updates** - Watches: `cards.{cardId}`

**Event Handling:**
- `RealtimeEventType`: create, update, delete
- `RealtimeEvent`: contains type, documentId, collection, data
- `RealtimeSubscription` management with cleanup

**Provider:**
```dart
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

**Key Method:**
```dart
Stream<RealtimeEvent> subscribeToBoardUpdates(String boardId)
```

### 2.2 Real-time Integration in Board Provider

**File:** `C:\Users\austi\projects\ollie\lib\providers\board_provider.dart`

- `BoardNotifier` sets up real-time listener in `_setupRealtimeListener()`
- Handles events via `_handleRealtimeEvent()` which routes to:
  - `_handleBoardEvent()` - Board metadata changes
  - `_handleColumnEvent()` - Column create/update/delete
  - `_handleCardEvent()` - Card create/update/delete/move
- Auto-refresh on changes using Appwrite real-time events

---

## 3. Main Board/Kanban View

### 3.1 Board Screen Structure

**File:** `C:\Users\austi\projects\ollie\lib\screens\board\board_screen.dart`

**Layout:**
- Desktop: Horizontal scrollable columns
- Mobile: Vertical scrollable columns list

**Key Components:**
1. **Header** (`_buildHeader()`)
   - Board title, back button
   - Sprint selector
   - Member avatars
   - Menu button

2. **Kanban Board** (`_buildKanbanBoard()`)
   - `KanbanColumn` widgets for each column
   - Real-time updates via `boardNotifierProvider(boardId)`
   - Drag-and-drop support via `moveCard()`

3. **Board Notifier Access:**
   ```dart
   final boardState = ref.watch(boardNotifierProvider(widget.boardId));
   ```

### 3.2 Kanban Column Component

**File:** `C:\Users\austi\projects\ollie\lib\components\kanban_column.dart`

**Structure:**
- `KanbanColumn` - ConsumerStatefulWidget
- `EnhancedColumnHeader` - Column title and controls
- Card list rendering
- Add card button

**Current State:**
- `_hoveredCardId` - Tracks which card is hovered
- Animation controller for scale effects
- Responsive width handling (mobile vs desktop)

**Where Cursors Would Be Displayed:**
- Inside column containers (overlay on card list)
- Potentially in header showing "User X is editing here"
- On individual cards when user is focused on that card

### 3.3 Kanban Card Component

**File:** `C:\Users\austi\projects\ollie\lib\components\kanban_card.dart`

Individual card rendering with:
- Card content (title, description, assignees)
- Drag-and-drop handlers
- Edit/delete actions

---

## 4. Team/Workspace Collaboration Structure

### 4.1 Board Model

**File:** `C:\Users\austi\projects\ollie\lib\models\board.dart`

```dart
class Board {
  final String id;
  final String name;
  final String? description;
  final String createdBy;           // Owner/creator user ID
  final List<String> memberIds;      // All users with access
  final List<String> columnIds;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Key Points:**
- `createdBy`: Single owner
- `memberIds`: List of user IDs with access
- Member management via `addMember()` and `removeMember()` in repository

### 4.2 User Model

**File:** `C:\Users\austi\projects\ollie\lib\models\user.dart`

```dart
class User {
  final String id;           // Appwrite Account ID
  final String name;
  final String email;
  final String? avatarUrl;   // Available for cursor display
}
```

### 4.3 Board Member Management

**File:** `C:\Users\austi\projects\ollie\lib\repositories\appwrite\appwrite_board_repository.dart`

```dart
Future<void> addMember(String boardId, String userId)
Future<void> removeMember(String boardId, String userId)
```

**UI Component:** `ManageMembersDialog` (line 191 in board_screen.dart)

### 4.4 Authentication & Current User

**File:** `C:\Users\austi\projects\ollie\lib\providers\auth_provider.dart`

- `authProvider`: StateNotifier tracking authenticated user
- `AppwriteConfig.currentUser`: Appwrite User model
- User ID available via: `authState.user?.$id`

**File:** `C:\Users\austi\projects\ollie\lib\providers\user_provider.dart`

- `currentUserProvider`: Fetches custom User model from database
- `userProvider`: Family provider for fetching users by ID
- `usersProvider`: Batch fetch multiple users

---

## 5. State Management Architecture

### 5.1 Riverpod Usage

**Technology:** Flutter Riverpod v3.0.3

**Provider Types Used:**
1. **Provider** - Singleton instances (AppwriteConfig, repositories)
2. **FutureProvider** - One-time async operations
3. **StreamProvider** - Continuous streams (real-time updates)
4. **StateNotifierProvider** - Mutable state (board, auth, boards list)
5. **FamilyModifier** - Parameterized providers (board-specific, user-specific)

### 5.2 Key State Management Files

**Authentication:**
- `C:\Users\austi\projects\ollie\lib\providers\auth_provider.dart` - AuthStateNotifier
- `C:\Users\austi\projects\ollie\lib\state\auth_state.dart` - AuthState model

**Boards List:**
- `C:\Users\austi\projects\ollie\lib\providers\boards_provider.dart` - BoardsNotifier, manages user's boards

**Single Board State:**
- `C:\Users\austi\projects\ollie\lib\providers\board_provider.dart` - BoardNotifier
  - Manages: board metadata, columns, cards for a specific board
  - Real-time subscriptions
  - Card operations (create, move, update, delete)

**Other State:**
- `boardsProvider` - User's board list
- `boardProvider` - Single board fetch
- `boardColumnsProvider` - Columns for a board
- `columnCardsProvider` - Cards in a column (with real-time)
- `sprintNotifierProvider` - Active sprint
- `burndownProvider` - Burndown chart data

### 5.3 State Pattern: BoardNotifier Example

```dart
class BoardNotifier extends StateNotifier<AsyncValue<BoardState>> {
  final BoardRepository _repository;
  final RealtimeService _realtimeService;
  
  // Initialization
  BoardNotifier(...) : super(const AsyncValue.loading()) {
    _loadBoard();
    _setupRealtimeListener();
  }
  
  // Real-time listener
  void _setupRealtimeListener() {
    _realtimeSubscription = _realtimeService
        .subscribeToBoardUpdates(_boardId)
        .listen(_handleRealtimeEvent);
  }
  
  // Operations with optimistic updates
  Future<void> moveCard(...) async {
    // 1. Optimistically update UI
    state = AsyncValue.data(currentState.copyWith(...));
    
    // 2. Sync with server
    try {
      await _repository.moveCard(...);
    } catch (e) {
      // 3. Rollback on error
      state = previousState;
    }
  }
}
```

---

## 6. Key Files for Cursor Tracking Implementation

### PRIORITY 1: Core Cursor Infrastructure

#### 1. **New File: `lib/models/cursor.dart`**
   - Cursor data model with position, user info
   - Required fields: userId, userName, userColor, position, timestamp
   - Optional: cardId, columnId for context

#### 2. **New File: `lib/services/cursor_service.dart`**
   - Similar to RealtimeService but for cursor updates
   - Methods:
     - `subscribeToCursorUpdates(boardId)` - Get all cursors
     - `publishCursorUpdate(boardId, cursor)` - Broadcast own cursor
     - `unsubscribeFromCursorUpdates(boardId)`
   - Uses Appwrite Realtime on `cursors` collection
   - Handles cursor cleanup (remove stale cursors)

#### 3. **New File: `lib/repositories/appwrite/appwrite_cursor_repository.dart`**
   - CRUD operations for cursor collection
   - Methods:
     - `createOrUpdateCursor(cursor)` - Write cursor position
     - `deleteCursor(userId, boardId)` - Cleanup on disconnect
     - `getCursorsByBoard(boardId)` - Get all active cursors
   - Implements: `CursorRepository` (new interface)

#### 4. **New File: `lib/repositories/cursor_repository.dart`**
   - Abstract interface for cursor persistence
   - Backend-agnostic

### PRIORITY 2: State Management for Cursors

#### 5. **New File: `lib/providers/cursor_provider.dart`**
   - `CursorState` model
   - `CursorNotifier` StateNotifier
   - Providers:
     - `cursorServiceProvider` - Singleton cursor service
     - `boardCursorsProvider` - Stream of cursors for board
     - `cursorNotifierProvider` - Mutable cursor state
   - Auto-publish local cursor on move/click

#### 6. **New File: `lib/state/cursor_state.dart`**
   - CursorState model with list of active cursors
   - Copy pattern for updates

### PRIORITY 3: UI Components for Cursor Display

#### 7. **New File: `lib/components/cursor_overlay.dart`**
   - Custom painter for cursor trails
   - Position-based rendering
   - Avatar display with user info
   - Handles multiple concurrent cursors
   - Fade-out animation for stale cursors

#### 8. **Modify File: `lib/components/kanban_column.dart`**
   - Add CursorOverlay on top of card list
   - Listen to `boardCursorsProvider`
   - Convert column-level positions to screen coordinates

#### 9. **Modify File: `lib/screens/board/board_screen.dart`**
   - Track mouse/touch position
   - Publish position changes (throttled)
   - Handle user focus/blur (cleanup cursors on blur)
   - Display "User X is viewing" indicators

### PRIORITY 4: Appwrite Collection Setup

#### 10. **New File: `appwrite_collection_schema.md`**
   - Document required `cursors` collection schema:
     ```
     cursors {
       id: String (userId-boardId)
       userId: String (indexed)
       boardId: String (indexed)
       userName: String
       userColor: String (hex color)
       position: Object {
         x: Float
         y: Float
         columnId: String? (optional context)
         cardId: String? (optional context)
       }
       timestamp: DateTime (for TTL/cleanup)
     }
     ```

### PRIORITY 5: Integration Points

#### 11. **Modify File: `lib/providers/board_provider.dart`**
   - Include cursor updates in board state
   - Handle cursor cleanup on board unload
   - Coordinate cursor updates with card updates

#### 12. **Modify File: `lib/main.dart`**
   - Initialize cursor service alongside realtime service
   - Ensure proper cleanup on app lifecycle

#### 13. **Modify File: `pubspec.yaml`**
   - No new dependencies needed
   - Uses existing: appwrite, flutter_riverpod

---

## 7. Integration Points Summary

### Real-time Event Flow for Cursors

```
User moves mouse on board
    ↓
BoardScreen detects MouseRegion event
    ↓
Publishes to cursorNotifierProvider (throttled ~100ms)
    ↓
CursorNotifier calls repository.updateCursor()
    ↓
Appwrite documents update, triggers Realtime event
    ↓
boardCursorsProvider stream receives update
    ↓
CursorOverlay rebuilds and renders cursor
```

### State Hierarchy

```
AuthProvider (who is logged in)
├─ CurrentUserProvider (detailed user info)
│  └─ Used for cursor color/name display
│
BoardsProvider (all user's boards)
│
BoardNotifierProvider(boardId) (board state)
├─ Board metadata, columns, cards
├─ Real-time card/column updates
└─ CursorNotifierProvider(boardId) ← NEW
   ├─ List of active cursors
   ├─ Real-time cursor updates
   └─ Local cursor position tracking
```

### Coordinate System

**Desktop (Horizontal Scroll):**
- Global screen coordinates
- Adjust for ScrollController position
- Offset by board container position

**Mobile (Vertical Scroll):**
- Global screen coordinates
- Adjust for ListView scroll offset
- Full-width columns

---

## 8. Data Collection & Queries

### Appwrite Queries for Cursors Collection

```dart
// Get all active cursors for a board
Query.equal('boardId', boardId)

// Get specific user's cursor
Query.equal('userId', userId)
Query.equal('boardId', boardId)

// Get cursors in last 30 seconds (for cleanup)
Query.lessThan('timestamp', DateTime.now().subtract(Duration(seconds: 30)))
```

### Indexes to Create

In Appwrite console for `cursors` collection:
- Composite index: `(boardId, timestamp)` - for cleanup queries
- Single index: `userId` - for user-specific updates
- Single index: `boardId` - for board queries

---

## 9. Real-time Subscription Details

### Existing Realtime Pattern in Code

```dart
// From realtime_service.dart - PATTERN TO FOLLOW
_realtime.subscribe([
  'databases.${AppwriteConfig.databaseId}.collections.cards.documents',
  // ... more channels
]);

subscription.stream.listen(
  (response) {
    final event = RealtimeEvent.fromResponse(response);
    controller.add(event);
  },
);
```

### Cursor Realtime Subscription

```dart
// In new cursor_service.dart
_realtime.subscribe([
  'databases.${AppwriteConfig.databaseId}.collections.cursors.documents',
]);

// Listen for cursor position updates (create/update)
subscription.stream.listen(
  (response) {
    final event = RealtimeEvent.fromResponse(response);
    // Filter to current board
    if (event.data['boardId'] == boardId) {
      controller.add(event);
    }
  },
);
```

---

## 10. Performance Considerations

### Cursor Update Throttling

**Requirement:** Don't publish cursor every pixel movement
**Solution:** Throttle updates to ~100-200ms intervals

```dart
// In BoardScreen state
Timer? _cursorPublishTimer;

void _publishCursorPosition(Offset position) {
  // Cancel pending timer
  _cursorPublishTimer?.cancel();
  
  // Schedule publish after delay
  _cursorPublishTimer = Timer(
    Duration(milliseconds: 100),
    () => ref.read(cursorNotifierProvider(boardId).notifier)
        .publishCursor(position, cardId: _hoveredCardId),
  );
}
```

### Cursor Cleanup

**Problem:** Users disconnect without cleanup, stale cursors remain
**Solutions:**
1. Client-side: Remove cursor on app lifecycle (onDispose)
2. Server-side: TTL on cursor documents (30 seconds)
3. Periodic cleanup: Task that removes cursors older than 1 minute

### Memory Management

- **Max cursors per board:** Limit to number of board members
- **Stream subscription:** Properly cancelled in provider dispose
- **Position storage:** Only store last position (not history)

---

## 11. Testing Strategy

### Unit Tests
- CursorNotifier state transitions
- Cursor position calculations
- Throttling logic

### Integration Tests
- Cursor publish/subscribe flow
- Multiple users on same board
- Cursor cleanup on disconnect

### Manual Testing
- Single board, single user (verify cursor appears)
- Two browsers on same board (verify cursor sync)
- Mobile responsiveness (verify position accuracy)
- Rapid mouse movements (verify throttling works)

---

## 12. Deployment Checklist

- [ ] Create `cursors` collection in Appwrite
- [ ] Set up required indexes
- [ ] Implement cursor models
- [ ] Implement cursor service
- [ ] Implement cursor repository
- [ ] Implement cursor providers
- [ ] Create CursorOverlay component
- [ ] Integrate into BoardScreen
- [ ] Integrate into KanbanColumn
- [ ] Test with real-time updates
- [ ] Test cleanup/disconnect handling
- [ ] Performance test with many cursors
- [ ] Mobile testing

---

## 13. Key Files Reference Table

| File | Purpose | Status | Priority |
|------|---------|--------|----------|
| `appwrite_config.dart` | Appwrite init & auth | Exists | Reference |
| `realtime_service.dart` | Real-time subscriptions | Exists | Reference/Pattern |
| `board_provider.dart` | Board state management | Exists | Modify |
| `board_screen.dart` | Main kanban UI | Exists | Modify |
| `kanban_column.dart` | Column component | Exists | Modify |
| `cursor.dart` | NEW - Cursor model | Create | HIGH |
| `cursor_service.dart` | NEW - Cursor realtime | Create | HIGH |
| `appwrite_cursor_repository.dart` | NEW - Cursor persistence | Create | HIGH |
| `cursor_repository.dart` | NEW - Cursor interface | Create | HIGH |
| `cursor_provider.dart` | NEW - Cursor state mgmt | Create | HIGH |
| `cursor_state.dart` | NEW - Cursor state model | Create | HIGH |
| `cursor_overlay.dart` | NEW - Cursor rendering | Create | MEDIUM |

---

## 14. Code Architecture Summary

### Layered Architecture

```
┌─────────────────────────────────────────────┐
│          UI Layer                            │
│  ┌──────────────────────────────────────┐   │
│  │ BoardScreen, KanbanColumn           │   │
│  │ (renders cursors via CursorOverlay) │   │
│  └──────────────────────────────────────┘   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│       State Management Layer (Riverpod)      │
│  ┌──────────────────────────────────────┐   │
│  │ boardNotifierProvider                │   │
│  │ cursorNotifierProvider (NEW)         │   │
│  │ realtimeServiceProvider              │   │
│  │ cursorServiceProvider (NEW)          │   │
│  └──────────────────────────────────────┘   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│      Repository Layer (Data Access)          │
│  ┌──────────────────────────────────────┐   │
│  │ AppwriteBoardRepository              │   │
│  │ AppwriteCursorRepository (NEW)       │   │
│  │ UserRepository                        │   │
│  └──────────────────────────────────────┘   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│     Service Layer (Business Logic)           │
│  ┌──────────────────────────────────────┐   │
│  │ RealtimeService                      │   │
│  │ CursorService (NEW)                  │   │
│  └──────────────────────────────────────┘   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│      Backend (Appwrite)                      │
│  ┌──────────────────────────────────────┐   │
│  │ Collections:                         │   │
│  │ - boards, columns, cards             │   │
│  │ - cursors (NEW)                      │   │
│  │ Realtime Events                      │   │
│  └──────────────────────────────────────┘   │
└────────────────────────────────────────────┘
```

---

## 15. Next Steps

### Phase 1: Foundation (Cursor Infrastructure)
1. Create cursor data models
2. Implement cursor service (real-time subscriptions)
3. Create cursor repository layer
4. Set up Appwrite cursors collection

### Phase 2: State Management
1. Implement cursor provider & notifier
2. Integrate with board provider
3. Handle cursor lifecycle (create, update, delete)

### Phase 3: UI/UX
1. Create CursorOverlay component
2. Integrate into board screen
3. Test position accuracy and performance
4. Add visual feedback (colors, labels)

### Phase 4: Polish & Testing
1. Optimize throttling and performance
2. Handle edge cases (disconnects, network lag)
3. User testing on mobile and desktop
4. Cleanup and documentation

---

## Conclusion

The Ollie kanban board has excellent architecture for adding cursor tracking. The existing real-time infrastructure through Appwrite and clean state management with Riverpod provide a solid foundation. The implementation can follow the existing patterns (RealtimeService → Repository → Provider → UI) with minimal disruption to the current codebase.

The main areas of change will be:
1. **Board Screen** - Track and publish cursor position
2. **Kanban Column** - Display cursor overlays
3. **New Components** - Cursor service, repository, providers, and overlay UI

All changes are well-scoped and can be implemented incrementally with proper testing at each phase.
