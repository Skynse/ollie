import '../models/user.dart';

/// Abstract repository interface - backend agnostic
abstract class UserRepository {
  Future<User> getUser(String userId);
  Future<User> getCurrentUser();
  Future<List<User>> getUsersByIds(List<String> userIds);
  Future<User> updateUser(User user);
  Future<List<User>> searchUsers(String query);

  /// Invite a user by email to join a specific board
  Future<void> inviteUserByEmail(String email, {required String boardId});

  /// Search for users by email (exact match)
  Future<User?> getUserByEmail(String email);
}
