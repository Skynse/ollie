# Real-time Implementation Guide

## Overview
The app now uses Appwrite's real-time subscriptions instead of the old `ref.refresh()` pattern. This enables true collaborative features and live updates.

## Architecture

### 1. **RealtimeService** (`lib/services/realtime_service.dart`)
Central service that manages all Appwrite real-time subscriptions.

**Features:**
- Subscribe to board updates (cards, columns, board metadata)
- Subscribe to specific cards or columns
- Automatic cleanup when subscriptions are cancelled
- Event parsing and filtering

**Example:**
```dart
final realtimeService = ref.read(realtimeServiceProvider);

// Subscribe to all updates for a board
final stream = realtimeService.subscribeToBoardUpdates(boardId);
stream.listen((event) {
  if (event.type == RealtimeEventType.create) {
    print('New ${event.collection} created: ${event.documentId}');
  }
});

// Don't forget to unsubscribe when done
realtimeService.unsubscribeFromBoard(boardId);
```

### 2. **BoardNotifier** (refactored in `lib/providers/board_provider.dart`)
Now listens to real-time events automatically.

**What changed:**
- ✅ Removed all `refresh()` calls
- ✅ Added real-time listener in constructor
- ✅ Automatically updates state when Appwrite sends events
- ✅ Handles create, update, delete for boards and columns

**Before:**
```dart
await _repository.createColumn(newColumn);
await refresh(); // ❌ Manual refresh
```

**After:**
```dart
await _repository.createColumn(newColumn);
// ✅ Real-time listener handles the update automatically
```

### 3. **columnCardsProvider** (refactored)
Changed from `FutureProvider` to `StreamProvider` for real-time card updates.

**Before:**
```dart
final columnCardsProvider = FutureProvider.family<List<Card>, String>(...);
// Would need manual invalidation
```

**After:**
```dart
final columnCardsProvider = StreamProvider.family<List<Card>, String>(...);
// Automatically updates when cards change via real-time
```

## How to Use

### Creating Cards (Real-time)
```dart
// Just create - no need to refresh!
final card = await ref
    .read(boardNotifierProvider(boardId).notifier)
    .createCard(
      columnId: columnId,
      title: 'New Task',
      description: 'This will appear in real-time',
      priority: Priority.high,
      createdBy: userId,
    );

// The UI updates automatically when Appwrite broadcasts the change
```

### Watching Cards in a Column
```dart
// In your widget
final cardsAsync = ref.watch(columnCardsProvider(columnId));

cardsAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
  data: (cards) => ListView.builder(
    itemCount: cards.length,
    itemBuilder: (context, index) => CardWidget(cards[index]),
  ),
);

// Cards update in real-time - no manual refresh needed!
```

### Adding Member Assignment (Example)

Here's how you'd implement real-time member assignment:

```dart
// 1. Create the method in BoardNotifier
Future<void> assignMemberToCard({
  required String cardId,
  required String userId,
}) async {
  try {
    final card = await _repository.getCard(cardId);
    final updatedAssignees = [...card.assigneeIds, userId];
    
    final updatedCard = card.copyWith(assigneeIds: updatedAssignees);
    await _repository.updateCard(updatedCard);
    
    // Real-time will handle the update!
  } catch (e) {
    print('Failed to assign member: $e');
  }
}

// 2. In your UI
IconButton(
  icon: Icon(Icons.person_add),
  onPressed: () async {
    await ref
        .read(boardNotifierProvider(boardId).notifier)
        .assignMemberToCard(
          cardId: card.id,
          userId: selectedUserId,
        );
    
    // The card updates automatically via real-time
    // All users see the change instantly!
  },
)
```

### Tracking Active Members (Presence)

Presence tracking can be added later using Appwrite's real-time presence features. For now, you can track board members using the `usersProvider`:

```dart
// Fetch all board members
final board = ref.watch(boardNotifierProvider(boardId)).value;
final memberIds = board?.board.memberIds ?? [];
final membersAsync = ref.watch(usersProvider(memberIds));

membersAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error loading members'),
  data: (members) => Row(
    children: members.map((member) => 
      CircleAvatar(child: Text(member.name[0]))
    ).toList(),
  ),
);
```

### Caching Member Data

Use the new `userProvider` to cache member info:

```dart
// Fetch a single user (cached)
final userAsync = ref.watch(userProvider(userId));

// Fetch multiple users (cached)
final usersAsync = ref.watch(usersProvider([userId1, userId2, userId3]));

// In your widget
userAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error loading user'),
  data: (user) => Text(user.name),
);
```

## Benefits

✅ **No more `ref.refresh()`** - Updates happen automatically  
✅ **No more `ref.invalidate()`** - Real-time keeps providers in sync  
✅ **True collaboration** - Multiple users see changes instantly  
✅ **Better UX** - No loading spinners after CRUD operations  
✅ **Cached data** - Members/users are fetched once and cached  
✅ **Scalable** - Easy to add more real-time features  

## Key Collections

The RealtimeService subscribes to these Appwrite collections:
- `cards` - All card CRUD operations
- `columns` - Column creation, updates, deletion
- `boards` - Board metadata changes

## Migration Checklist

- [x] Create `RealtimeService`
- [x] Refactor `BoardNotifier` to use real-time
- [x] Convert `columnCardsProvider` to `StreamProvider`
- [x] Remove `ref.refresh()` from all CRUD operations
- [x] Remove `ref.invalidate()` from card creation
- [x] Clean up board_screen.dart (remove commented code)
- [x] Add user caching providers

## Next Steps

1. Test creating cards - they should appear instantly
2. Test deleting cards/columns - they should disappear instantly
3. Open the board in multiple browsers/tabs - changes should sync
4. Implement member assignment with real-time updates
5. Add drag-and-drop card reordering (will auto-sync via real-time!)

## Troubleshooting

**Cards not updating?**
- Check Appwrite real-time is enabled in your project settings
- Verify the database ID in `AppwriteConfig.databaseId`
- Check browser console for WebSocket errors

**Multiple fetches happening?**
- This is normal on first load (initial fetch + real-time subscription)
- Subsequent changes should only trigger one fetch

**Want to see real-time events?**
Add this to `BoardNotifier._handleRealtimeEvent`:
```dart
print('Real-time event: ${event.collection} ${event.type} ${event.documentId}');
```
