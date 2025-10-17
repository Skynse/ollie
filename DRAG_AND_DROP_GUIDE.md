# Drag and Drop Guide

Complete real-time drag and drop for moving cards between columns.

## Features

✅ **Long-press to drag** - Press and hold a card to start dragging  
✅ **Visual feedback** - Dragged card shows with opacity and elevation  
✅ **Drop zones** - Columns highlight when hovering with a card  
✅ **Real-time sync** - All users see card movements instantly  
✅ **Prevents same-column drops** - Can't drop a card in its current column  

---

## How to Use

### Desktop/Web
1. **Long-press** a card (hold for ~0.5 seconds)
2. **Drag** the card to another column
3. **Release** to drop the card

### Mobile
1. **Long-press** a card
2. **Drag** to another column
3. **Lift finger** to drop

### Visual Feedback
- **Original card**: Becomes semi-transparent (30% opacity)
- **Drag preview**: Shows with elevation and 80% opacity
- **Target column**: Highlights with blue background when hovering

---

## Architecture

### Components Modified

#### `lib/components/kanban_card.dart`
Made cards draggable using `LongPressDraggable`:

```dart
LongPressDraggable<model.Card>(
  data: card,  // Pass card data
  feedback: Material(...),  // Drag preview
  childWhenDragging: Opacity(...),  // Original card while dragging
  child: _buildCardContent(...),  // Normal card
)
```

#### `lib/components/kanban_column.dart`
Made columns accept dropped cards using `DragTarget`:

```dart
DragTarget<model.Card>(
  onWillAcceptWithDetails: (details) => 
    details.data.columnId != column.id,  // Only accept from other columns
  onAcceptWithDetails: (details) async {
    await moveCard(...);  // Update in Appwrite
  },
  builder: (context, candidateData, rejectedData) {
    final isHovering = candidateData.isNotEmpty;
    // Show blue highlight when hovering
  },
)
```

#### `lib/providers/board_provider.dart`
Added `moveCard()` method:

```dart
Future<void> moveCard({
  required String cardId,
  required String targetColumnId,
  required int targetPosition,
}) async {
  await _repository.moveCard(cardId, targetColumnId, targetPosition);
  // Real-time listener handles UI updates automatically
}
```

---

## Real-time Behavior

### When you drag a card:
1. You long-press and drag the card
2. Drop it on another column
3. `moveCard()` updates Appwrite
4. Appwrite broadcasts the change
5. `columnCardsProvider` receives the event
6. Both columns refetch their cards
7. **All users see the movement instantly!**

### Multi-user Scenario
- **User A** drags "Design mockups" from "To Do" → "In Progress"
- **User B** sees the card disappear from "To Do"
- **User B** sees the card appear in "In Progress"
- **No page refresh needed!**

---

## Implementation Details

### Why Long Press?
- Prevents accidental drags
- Works better on mobile
- Doesn't conflict with scrolling
- Allows right-click menu to still work

### Card Positioning
Currently, dropped cards go to position `0` (top of column).

**To customize position:**
```dart
onAcceptWithDetails: (details) async {
  // Calculate target position based on drop location
  final targetPosition = _calculateDropPosition(details.offset);
  
  await ref.read(boardNotifierProvider(boardId).notifier).moveCard(
    cardId: details.data.id,
    targetColumnId: column.id,
    targetPosition: targetPosition,
  );
}
```

### Drag Feedback
The dragged card shows:
- Width: 280px (fixed for consistency)
- Elevation: 8 (shadow effect)
- Opacity: 0.8 (slightly transparent)
- Border radius: 8px (matches card style)

---

## Future Enhancements

### 1. **Precise Drop Position**
Drop cards between specific cards, not just at the top:

```dart
// Wrap each card in a DragTarget
DragTarget<model.Card>(
  onAcceptWithDetails: (details) async {
    // Drop above this card
    await moveCard(
      cardId: details.data.id,
      targetColumnId: column.id,
      targetPosition: index,  // Drop at this position
    );
  },
  builder: (context, candidateData, rejectedData) {
    return Column(
      children: [
        // Show drop indicator line when hovering
        if (candidateData.isNotEmpty)
          Container(
            height: 2,
            color: Colors.blue,
            margin: EdgeInsets.symmetric(horizontal: 12),
          ),
        KanbanCard(...),
      ],
    );
  },
)
```

### 2. **Drag Handle**
Add an explicit handle to make dragging more intuitive:

```dart
Row(
  children: [
    // Drag handle icon
    Icon(Icons.drag_indicator, color: Colors.grey),
    SizedBox(width: 8),
    Expanded(child: Text(card.title)),
  ],
)
```

### 3. **Multi-select Drag**
Select multiple cards and drag them together:
- Click checkboxes to select cards
- Drag any selected card
- All selected cards move together

### 4. **Column Reordering**
Make columns draggable too:

```dart
ReorderableListView(
  onReorder: (oldIndex, newIndex) async {
    // Reorder columns
    await updateColumnPositions(...);
  },
  children: columns.map((column) => 
    ColumnWidget(key: ValueKey(column.id), column: column)
  ).toList(),
)
```

### 5. **Drag Animations**
Add smooth animations when cards are dropped:

```dart
AnimatedList(
  // Animate card insertions/removals
)
```

### 6. **Undo/Redo**
Track moves and allow undo:

```dart
class MoveHistory {
  final String cardId;
  final String fromColumnId;
  final String toColumnId;
  final DateTime timestamp;
}

// Undo button
onPressed: () async {
  final lastMove = moveHistory.last;
  await moveCard(
    cardId: lastMove.cardId,
    targetColumnId: lastMove.fromColumnId,
    targetPosition: 0,
  );
}
```

---

## Troubleshooting

**Cards won't drag?**
- Make sure you're long-pressing (not just tapping)
- Check that `LongPressDraggable` is wrapping the card
- Verify `data` is being passed correctly

**Cards drop but don't move?**
- Check real-time connection (WebSocket)
- Verify `moveCard()` is being called
- Look for errors in console

**Dragging feels laggy?**
- Reduce feedback widget complexity
- Use `Opacity` widget instead of rebuilding
- Check for heavy computations in build methods

**Drop zones not highlighting?**
- Verify `candidateData.isNotEmpty` check
- Ensure `onWillAcceptWithDetails` returns true
- Check that card data types match

**Cards disappear after dropping?**
- Real-time might be delayed
- Check Appwrite real-time status
- Verify `columnCardsProvider` is refetching

---

## API Reference

### moveCard()
```dart
Future<void> moveCard({
  required String cardId,        // Card to move
  required String targetColumnId, // Destination column
  required int targetPosition,    // Position in column (0 = top)
})
```

### LongPressDraggable
```dart
LongPressDraggable<T>(
  data: T,                        // Data to pass
  feedback: Widget,               // Widget shown while dragging
  childWhenDragging: Widget,      // Original widget appearance
  child: Widget,                  // Normal widget
)
```

### DragTarget
```dart
DragTarget<T>(
  onWillAcceptWithDetails: (details) => bool,  // Can accept drop?
  onAcceptWithDetails: (details) => void,      // Handle drop
  builder: (context, candidateData, rejectedData) => Widget,
)
```

---

## Performance Tips

1. **Keep feedback widget simple** - Complex widgets slow down dragging
2. **Use const constructors** - Reduce rebuilds during drag
3. **Limit real-time listeners** - Only subscribe to necessary updates
4. **Debounce position updates** - Don't update on every pixel movement
5. **Cache card data** - Use providers to avoid repeated fetches

---

Enjoy your real-time drag and drop! 🎯
