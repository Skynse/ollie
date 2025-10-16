import 'package:appwrite/appwrite.dart';
import '../../models/user.dart';
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
}
