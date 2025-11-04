# Cursor Tracking - Quick Reference Guide

## Current Architecture Overview

### Appwrite Setup (PRODUCTION)
```
Endpoint: https://sfo.cloud.appwrite.io/v1
Project: 68f0a62200038266c6c3 (ollie)
Database: 68f0c0100009393371fd

Existing Collections:
├── boards (board metadata + memberIds)
├── columns (column definitions)
├── cards (task cards)
├── labels (card tags)
├── comments (card discussions)
├── checklists (card subtasks)
└── cursors (TO BE CREATED)
```

### State Management Stack
```
Flutter Riverpod 3.0.3
├── Providers (singletons)
├── FutureProviders (one-time async)
├── StreamProviders (real-time)
└── StateNotifiers (mutable state)
```

### Real-time Architecture Pattern
```
User Action (move card, click position)
        ↓
BoardNotifier / CursorNotifier (update state)
        ↓
Repository (persist to Appwrite)
        ↓
Appwrite Document Update
        ↓
Realtime Event Broadcast
        ↓
Service subscribes & broadcasts to app
        ↓
Provider stream updates
        ↓
UI rebuilds (board_screen, kanban_column)
```

---

## Files: What Exists vs What's Needed

### EXISTING FILES (Reference/Modify)

| File | Key Classes | Use For |
|------|------------|---------|
| `appwrite_config.dart` | AppwriteConfig | Appwrite initialization pattern |
| `realtime_service.dart` | RealtimeService, RealtimeEvent | Copy pattern for CursorService |
| `board_provider.dart` | BoardNotifier, BoardState | Copy pattern for CursorNotifier |
| `board_screen.dart` | BoardScreen | Add MouseRegion for cursor tracking |
| `kanban_column.dart` | KanbanColumn | Add CursorOverlay widget |
| `auth_provider.dart` | AuthStateNotifier | Current user ID (userId) |
| `user_provider.dart` | userProvider family | Fetch user info for cursor display |

### NEW FILES TO CREATE

**Core Infrastructure (MUST CREATE):**
1. `lib/models/cursor.dart` - Cursor data model
2. `lib/services/cursor_service.dart` - Real-time cursor subscriptions
3. `lib/repositories/cursor_repository.dart` - Abstract interface
4. `lib/repositories/appwrite/appwrite_cursor_repository.dart` - Appwrite impl
5. `lib/providers/cursor_provider.dart` - Riverpod state management
6. `lib/state/cursor_state.dart` - CursorState model

**UI Components (MUST CREATE):**
7. `lib/components/cursor_overlay.dart` - Render cursors on board

**Supporting (NICE TO HAVE):**
8. `appwrite_collection_schema.md` - Collection documentation
9. `CURSOR_IMPLEMENTATION_GUIDE.md` - Step-by-step dev guide

---

## File Modification Checklist

### 1. `lib/main.dart`
```diff
+ Ensure cursor service initialized with realtime service
+ Call cleanup on app lifecycle
```

### 2. `lib/screens/board/board_screen.dart`
```diff
+ Add MouseRegion wrapper around board content
+ Track mouse position state
+ Call cursorNotifierProvider to publish position
+ Implement throttling (~100ms)
+ Handle focus/blur for cleanup
```

### 3. `lib/components/kanban_column.dart`
```diff
+ Add listener to boardCursorsProvider(boardId)
+ Pass cursor list to CursorOverlay
+ Render CursorOverlay above card list
```

### 4. `lib/providers/board_provider.dart`
```diff
+ Cleanup cursor subscriptions in dispose
+ Optional: include cursor state in BoardState
```

### 5. `pubspec.yaml`
```diff
# No changes needed - already have appwrite and flutter_riverpod
```

---

## Cursor Model & Data Flow

### Cursor Data Structure

```dart
class Cursor {
  final String id;                    // ${userId}-${boardId}
  final String userId;
  final String userName;
  final String userColor;             // Hex: #RRGGBB
  final double x, y;                  // Screen coordinates
  final String? cardId;               // Optional context
  final String? columnId;             // Optional context
  final DateTime timestamp;
  
  // Methods:
  // toJson() - for Appwrite persistence
  // fromJson() - from Appwrite documents
  // copyWith() - for updates
}
```

### Appwrite Collection Schema

```json
// Appwrite Console: Collections > cursors

{
  "collectionId": "cursors",
  "databaseId": "68f0c0100009393371fd",
  "attributes": [
    {
      "key": "userId",
      "type": "string",
      "required": true,
      "default": null
    },
    {
      "key": "boardId",
      "type": "string",
      "required": true,
      "default": null
    },
    {
      "key": "userName",
      "type": "string",
      "required": true
    },
    {
      "key": "userColor",
      "type": "string",
      "required": true
    },
    {
      "key": "x",
      "type": "float",
      "required": true
    },
    {
      "key": "y",
      "type": "float",
      "required": true
    },
    {
      "key": "cardId",
      "type": "string",
      "required": false
    },
    {
      "key": "columnId",
      "type": "string",
      "required": false
    },
    {
      "key": "timestamp",
      "type": "datetime",
      "required": true
    }
  ],
  "indexes": [
    {
      "key": "boardId_timestamp",
      "attributes": ["boardId", "timestamp"],
      "orders": ["ASC", "DESC"]
    },
    {
      "key": "userId",
      "attributes": ["userId"]
    }
  ]
}
```

---

## Implementation Sequence

### Step 1: Create Cursor Model
**File:** `lib/models/cursor.dart`
- Simple POJO with toJson/fromJson
- Required: id, userId, userName, userColor, x, y, boardId, timestamp
- Optional: cardId, columnId

### Step 2: Create Cursor Repository Layer
**Files:** 
- `lib/repositories/cursor_repository.dart` (interface)
- `lib/repositories/appwrite/appwrite_cursor_repository.dart` (impl)

**Methods:**
- `createOrUpdateCursor(Cursor)` - upsert
- `deleteCursor(String userId, String boardId)` - cleanup
- `getCursorsByBoard(String boardId)` - fetch all

### Step 3: Create Cursor Service
**File:** `lib/services/cursor_service.dart`

**Similar to RealtimeService:**
```dart
class CursorService {
  // Subscribe to cursor updates for a board
  Stream<RealtimeEvent> subscribeToCursorUpdates(String boardId)
  
  // Cleanup
  void unsubscribeFromBoard(String boardId)
  void dispose()
}

// Provider
final cursorServiceProvider = Provider<CursorService>((ref) {
  final service = CursorService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

### Step 4: Create Cursor State Management
**Files:**
- `lib/state/cursor_state.dart` - State model
- `lib/providers/cursor_provider.dart` - Notifier + providers

**CursorState:**
```dart
class CursorState {
  final List<Cursor> activeCursors;
  final bool isLoading;
  final String? errorMessage;
}
```

**CursorNotifier methods:**
```dart
Future<void> publishCursor(Offset position, {String? cardId})
Future<void> setupBoardListener(String boardId)
void clearBoard(String boardId)
```

### Step 5: Create Cursor UI Component
**File:** `lib/components/cursor_overlay.dart`

**CursorOverlay widget:**
```dart
class CursorOverlay extends StatelessWidget {
  final List<Cursor> cursors;
  final Size boardSize;
  
  // Renders:
  // 1. Custom cursors with user avatars
  // 2. User name labels
  // 3. Fade-out animation for stale cursors
}
```

### Step 6: Integrate into BoardScreen
**File:** `lib/screens/board/board_screen.dart`

**Changes:**
```dart
// Add MouseRegion to track position
MouseRegion(
  onHover: (event) => _updateCursorPosition(event.localPosition),
  onExit: (_) => _clearCursorPosition(),
  child: // ... existing board content
)

// Add cursor publishing (throttled)
void _updateCursorPosition(Offset position) {
  _publishTimer?.cancel();
  _publishTimer = Timer(Duration(milliseconds: 100), () {
    ref.read(cursorNotifierProvider(boardId).notifier)
        .publishCursor(position, cardId: _hoveredCardId);
  });
}
```

### Step 7: Integrate into KanbanColumn
**File:** `lib/components/kanban_column.dart`

**Changes:**
```dart
// Watch cursor provider
final cursors = ref.watch(boardCursorsProvider(boardId));

// Add overlay
Stack(
  children: [
    // Existing column content
    ...existing_widgets,
    
    // New cursor overlay
    cursors.when(
      data: (list) => CursorOverlay(
        cursors: list,
        boardSize: Size(280, constraints.maxHeight),
      ),
      // ... loading/error
    ),
  ],
)
```

---

## Testing Checklist

### Unit Tests
- [ ] Cursor model serialization
- [ ] CursorNotifier state updates
- [ ] Throttling logic (100ms delay)
- [ ] Coordinate calculations

### Integration Tests
- [ ] Publish cursor → Appwrite → Subscribe
- [ ] Multiple cursors on same board
- [ ] Cursor cleanup on app lifecycle

### Manual Tests
- [ ] Single user - cursor appears
- [ ] Two browsers same board - cursors sync
- [ ] Mobile - touch position accuracy
- [ ] Rapid mouse movement - throttling works
- [ ] Network disconnect - cleanup works
- [ ] Long board session - no memory leaks

---

## Performance Guidelines

### Throttling
```
Default: 100-200ms between publishes
Rationale: Smooth for real-time feel, not overwhelming DB
Tunable via: Duration(milliseconds: X) in timer
```

### Memory
```
Max cursors per board = number of board members
Typical: 5-20 cursors per board
Storage per cursor: ~200 bytes
Stream subscription: auto-cleaned by Riverpod
```

### Network
```
Appwrite Realtime: WebSocket-based (efficient)
Update frequency: ~5-10 updates/second per user
Bandwidth: ~1KB per update
Cleanup: Server-side TTL (30 sec) + client cleanup
```

---

## Common Issues & Solutions

### Issue: Cursor position off on mobile
**Solution:** Account for ScrollController offset and screen orientation

### Issue: Stale cursors remain on board
**Solution:** 
1. Client cleanup on app lifecycle
2. Server TTL (expire docs after 30 seconds)
3. Periodic cleanup query

### Issue: Too many Realtime events
**Solution:** Implement throttling (100ms minimum interval)

### Issue: Memory leak from subscriptions
**Solution:** Proper disposal in provider onDispose

---

## Key Patterns to Follow

### From RealtimeService
```dart
// Pattern 1: Singleton service with disposal
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Pattern 2: Stream subscription with cleanup
Stream<RealtimeEvent> subscribe() {
  controller.onCancel = () {
    subscription.cancel();
    service.unsubscribe(key);
  };
}
```

### From BoardNotifier
```dart
// Pattern 3: Optimistic updates with rollback
Future<void> moveCard() async {
  final previousState = state;
  // Update UI immediately
  state = AsyncValue.data(newState);
  
  try {
    // Persist to server
    await repository.moveCard(...);
  } catch (e) {
    // Rollback on error
    state = previousState;
  }
}
```

### From BoardScreen
```dart
// Pattern 4: Provider family for board-specific state
final boardState = ref.watch(boardNotifierProvider(boardId));

// Pattern 5: Throttled updates
Timer? _timer;
void _handleEvent() {
  _timer?.cancel();
  _timer = Timer(Duration(milliseconds: 100), () {
    // Do work
  });
}
```

---

## Appwrite Console Setup

### Prerequisites
- Access to Appwrite Console (https://sfo.cloud.appwrite.io)
- Project: ollie (68f0a62200038266c6c3)
- Database: 68f0c0100009393371fd

### Steps to Create cursors Collection

1. **Create Collection**
   - Database: 68f0c0100009393371fd
   - Name: cursors
   - Permissions: Keep default (user can write own cursors)

2. **Add Attributes**
   - userId: String, required
   - boardId: String, required
   - userName: String, required
   - userColor: String, required (hex color)
   - x: Float, required
   - y: Float, required
   - cardId: String, optional
   - columnId: String, optional
   - timestamp: DateTime, required

3. **Create Indexes**
   - Composite: (boardId, timestamp) for queries
   - Single: userId for user-specific lookups
   - Single: boardId for board-level subscriptions

4. **Set Permissions**
   - Create: Users can create their own cursor
   - Update: Users can update their own cursor
   - Delete: Users can delete their own cursor
   - Read: All board members can read

---

## Repository Structure (What Gets Created)

```
lib/
├── models/
│   └── cursor.dart                    ← NEW
│
├── repositories/
│   ├── cursor_repository.dart         ← NEW (interface)
│   └── appwrite/
│       └── appwrite_cursor_repository.dart  ← NEW (impl)
│
├── services/
│   └── cursor_service.dart            ← NEW
│
├── providers/
│   └── cursor_provider.dart           ← NEW
│
├── state/
│   └── cursor_state.dart              ← NEW
│
└── components/
    └── cursor_overlay.dart            ← NEW
```

---

## Quick Start Command

```bash
# 1. Create all new files (copy from templates provided)
# 2. Update appwrite console with cursors collection
# 3. In board_screen.dart: Add MouseRegion wrapper
# 4. In kanban_column.dart: Add CursorOverlay render
# 5. Test with flutter run
```

---

## Success Criteria

- [ ] Cursor appears when user moves mouse on desktop
- [ ] Cursor position syncs across multiple browsers
- [ ] Cursor removes when user leaves board
- [ ] No console errors or warnings
- [ ] Works on both desktop and mobile
- [ ] Handles network disconnects gracefully
- [ ] Performance is smooth (60fps)
- [ ] Memory usage stable over time

---

## Reference: Exact File Paths

| File | Full Path |
|------|-----------|
| Current Appwrite Config | `C:\Users\austi\projects\ollie\lib\repositories\appwrite\appwrite_config.dart` |
| Realtime Service | `C:\Users\austi\projects\ollie\lib\services\realtime_service.dart` |
| Board Notifier | `C:\Users\austi\projects\ollie\lib\providers\board_provider.dart` |
| Board Screen | `C:\Users\austi\projects\ollie\lib\screens\board\board_screen.dart` |
| Kanban Column | `C:\Users\austi\projects\ollie\lib\components\kanban_column.dart` |
| Environment Config | `C:\Users\austi\projects\ollie\lib\config\environment.dart` |
| Pubspec | `C:\Users\austi\projects\ollie\pubspec.yaml` |

---

## Notes for Implementation

1. **User Color Selection:** Can use hash of userId to generate deterministic color
2. **Cursor TTL:** Appwrite doesn't have native TTL, implement cleanup in provider
3. **Position Accuracy:** Mobile needs special handling for touch vs mouse
4. **Offline Mode:** Cursors won't persist if offline, queued updates acceptable
5. **Performance:** Test with 20+ cursors moving simultaneously
6. **Accessibility:** Add ARIA labels for cursor positions

---

**Document Generated:** 2025-11-04  
**Target Implementation:** Phase by phase, starting with Step 1
**Estimated Effort:** 2-3 days for full implementation
