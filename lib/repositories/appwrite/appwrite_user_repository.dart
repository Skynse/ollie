import 'package:appwrite/appwrite.dart';
import '../../models/user.dart';
import '../../models/invitation.dart';
import '../user_repository.dart';

class AppwriteUserRepository implements UserRepository {
  final Databases databases;
  final Account account;
  final String databaseId;

  AppwriteUserRepository({
    required this.databases,
    required this.account,
    required this.databaseId,
  });

  static const String usersCollection = 'users';
  static const String invitationsCollection = 'invitations';

  @override
  Future<User> getUser(String userId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: usersCollection,
      documentId: userId,
    );
    return User.fromJson(doc.data);
  }

  @override
  Future<User> getCurrentUser() async {
    final appwriteUser = await account.get();
    // Fetch from users collection using Appwrite account ID
    return getUser(appwriteUser.$id);
  }

  @override
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollection,
      queries: [Query.equal('\$id', userIds)],
    );
    return docs.documents.map((doc) => User.fromJson(doc.data)).toList();
  }

  @override
  Future<User> updateUser(User user) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: usersCollection,
      documentId: user.id,
      data: user.toJson(),
    );
    return User.fromJson(doc.data);
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollection,
      queries: [Query.search('name', query)],
    );
    return docs.documents.map((doc) => User.fromJson(doc.data)).toList();
  }

  @override
  Future<void> inviteUserByEmail(
    String email, {
    required String boardId,
  }) async {
    try {
      // Get current user to record who sent the invitation
      final currentUser = await account.get();

      // Check if there's already a pending invitation for this email
      final existingInvites = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: invitationsCollection,
        queries: [
          Query.equal('email', email),
          Query.equal('status', 'pending'),
        ],
      );

      // If invitation already exists, don't create duplicate
      if (existingInvites.documents.isNotEmpty) {
        return;
      }

      // Create invitation record
      final invitation = Invitation(
        id: ID.unique(),
        email: email.toLowerCase(),
        boardId: boardId,
        invitedBy: currentUser.$id,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
      );

      await databases.createDocument(
        databaseId: databaseId,
        collectionId: invitationsCollection,
        documentId: invitation.id,
        data: invitation.toJson(),
      );

      // TODO: Send email via Appwrite Functions or external service
      // For now, the invitation is just stored in the database
      // When the user signs up with this email, they can be auto-added to the board
    } catch (e) {
      throw Exception('Failed to create invitation: $e');
    }
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    try {
      final docs = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollection,
        queries: [Query.equal('email', email)],
      );

      if (docs.documents.isEmpty) return null;
      return User.fromJson(docs.documents.first.data);
    } catch (e) {
      print(e);
      return null;
    }
  }
}
