# Member Assignment & Invite Features

Complete guide for using the new member assignment and email invitation features.

## Features Implemented

### 1. **Assign Members to Cards** ✅
Right-click any card and select "Change Members" to assign/unassign board members.

### 2. **Invite by Email** ✅
Click the invite button in the board header to invite new users by email.

### 3. **Real-time Member Updates** ✅
All member assignments update instantly via Appwrite real-time.

### 4. **User Caching** ✅
Member data is cached in providers to avoid repeated fetches.

---

## Usage

### Assigning Members to a Card

1. **Right-click a card** on the Kanban board
2. Select **"Change Members"**
3. Check/uncheck members from the list
4. Click **"Save"**

Changes appear instantly on all connected clients!

```dart
// In code - assign a member
await ref
    .read(boardNotifierProvider(boardId).notifier)
    .assignMemberToCard(
      cardId: card.id,
      userId: userId,
    );

// Remove a member
await ref
    .read(boardNotifierProvider(boardId).notifier)
    .removeMemberFromCard(
      cardId: card.id,
      userId: userId,
    );
```

### Inviting Members by Email

1. Click the **"+"** button next to member avatars in the board header
2. Enter the email address
3. Click **"Invite"**

**Two scenarios:**

**User already exists:**
- They're immediately added to the board
- You'll see: "John Doe has been added to the board!"

**User doesn't exist yet:**
- An invitation is sent (requires Appwrite Functions setup)
- You'll see: "Invitation sent to user@example.com!"

```dart
// Show the invite dialog
showDialog(
  context: context,
  builder: (context) => InviteMemberDialog(boardId: boardId),
);
```

---

## Architecture

### New Files Created

#### `lib/components/assign_member_dialog.dart`
Dialog for assigning/removing members from cards. Features:
- Displays all board members
- Shows current assignments
- Checkbox selection
- Real-time updates

#### `lib/components/invite_member_dialog.dart`
Dialog for inviting users by email. Features:
- Email validation
- Checks if user exists
- Auto-adds existing users
- Sends invites for new users

### Modified Files

#### `lib/providers/board_provider.dart`
Added methods:
- `assignMemberToCard()` - Assign a user to a card
- `removeMemberFromCard()` - Remove a user from a card

#### `lib/providers/user_provider.dart`
Simplified caching provider for users:
- `userProvider` - Fetch single user (cached)
- `usersProvider` - Fetch multiple users (cached)

#### `lib/repositories/user_repository.dart`
Added methods:
- `inviteUserByEmail()` - Send email invitation
- `getUserByEmail()` - Find user by email

#### `lib/repositories/appwrite/appwrite_user_repository.dart`
Implemented new methods:
- `getUserByEmail()` - Query users by email
- `inviteUserByEmail()` - Placeholder for invitation logic

#### `lib/components/kanban_card.dart`
Enhanced card display:
- Shows member avatars with initials
- Tooltips with member names
- "+N" indicator for extra members
- Connected "Change Members" menu option

#### `lib/screens/board/board_screen.dart`
Board header improvements:
- Member avatars with real user data
- Invite button next to avatars
- Tooltips on hover

---

## Real-time Behavior

### When you assign a member:
1. `assignMemberToCard()` updates the card in Appwrite
2. Appwrite broadcasts the change via real-time
3. `columnCardsProvider` receives the event
4. Cards refetch automatically
5. UI updates instantly - **no manual refresh!**

### All connected users see:
- ✅ New member avatar appears on card
- ✅ Member count updates
- ✅ Assignment dialog reflects changes

---

## User Caching

Member data is cached using Riverpod's `FutureProvider`:

```dart
// Fetches once, then caches
final userAsync = ref.watch(userProvider(userId));

// Fetch multiple users in parallel
final usersAsync = ref.watch(usersProvider([id1, id2, id3]));
```

**Benefits:**
- No repeated API calls
- Fast avatar rendering
- Efficient for boards with many members

---

## Email Invitations

### Current Implementation
The `inviteUserByEmail()` method is a **placeholder** that throws `UnimplementedError`.

### To Enable Email Invitations:

You need to set up **Appwrite Functions** to send emails:

1. **Create an Appwrite Function** that:
   - Creates an invitation record
   - Sends an email via a service (SendGrid, Resend, etc.)
   - Includes a signup link with the boardId

2. **Update `AppwriteUserRepository.inviteUserByEmail()`:**

```dart
@override
Future<void> inviteUserByEmail(String email, {String? boardId}) async {
  // Create invitation record
  await databases.createDocument(
    databaseId: databaseId,
    collectionId: 'invitations',
    documentId: ID.unique(),
    data: {
      'email': email,
      'boardId': boardId,
      'createdAt': DateTime.now().toIso8601String(),
    },
  );
  
  // Trigger Appwrite Function to send email
  final functions = Functions(client);
  await functions.createExecution(
    functionId: 'send-invitation',
    body: jsonEncode({'email': email, 'boardId': boardId}),
  );
}
```

3. **Handle invitation on signup:**
   - Check for pending invitations
   - Auto-add user to boards
   - Delete processed invitations

---

## UI Components

### Member Avatars
- Circular with colored background
- Shows first letter of name
- Tooltip with full name
- Loading/error states

### Assignment Dialog
- List all board members
- Checkboxes for selection
- Shows email addresses
- Smooth animations

### Invite Dialog
- Email input with validation
- Loading states
- Success/error messages
- Auto-closes after success

---

## Error Handling

### Assign Member Errors
```dart
try {
  await assignMemberToCard(...);
} catch (e) {
  // Error stored in BoardState.errorMessage
  // Could show a snackbar here
}
```

### Invite Errors
- Invalid email: Form validation
- Network error: Error message in dialog
- User already on board: Success message

---

## Testing Checklist

- [ ] Assign member to card - appears instantly
- [ ] Remove member from card - disappears instantly
- [ ] Open board in two tabs - changes sync
- [ ] Invite existing user - adds to board
- [ ] Invite new user - shows invite sent message
- [ ] Member avatars load correctly
- [ ] Tooltips show on hover
- [ ] +N indicator shows for 4+ members
- [ ] Right-click menu works on cards

---

## Next Steps

### Recommended Enhancements

1. **Email Invitations**
   - Set up Appwrite Functions
   - Configure email service
   - Design invitation email template

2. **Member Permissions**
   - Add role-based access (admin, member, viewer)
   - Restrict who can invite
   - Protect sensitive operations

3. **Presence Tracking**
   - Show who's actively viewing the board
   - Real-time cursor positions
   - "User is typing..." indicators

4. **Bulk Operations**
   - Assign multiple cards at once
   - Remove member from all cards
   - Copy assignments between cards

5. **Notifications**
   - Notify users when assigned to cards
   - Email digests
   - In-app notification center

---

## API Reference

### BoardNotifier Methods

```dart
// Assign a member to a card
Future<void> assignMemberToCard({
  required String cardId,
  required String userId,
})

// Remove a member from a card
Future<void> removeMemberFromCard({
  required String cardId,
  required String userId,
})
```

### Providers

```dart
// Fetch single user (cached)
userProvider(String userId) -> FutureProvider<User>

// Fetch multiple users (cached)
usersProvider(List<String> userIds) -> FutureProvider<List<User>>
```

### Repository Methods

```dart
// Find user by email
Future<User?> getUserByEmail(String email)

// Send invitation (requires implementation)
Future<void> inviteUserByEmail(String email, {String? boardId})

// Add member to board
Future<void> addMember(String boardId, String userId)
```

---

## Troubleshooting

**Members not appearing on cards?**
- Check that userRepositoryProvider is properly configured
- Verify user IDs exist in the users collection

**Invite button not working?**
- Email invitations need Appwrite Functions setup
- Check console for UnimplementedError

**Real-time not updating?**
- Verify Appwrite real-time is enabled
- Check WebSocket connection
- Look for errors in browser console

---

Enjoy your new real-time collaborative features! 🎉
