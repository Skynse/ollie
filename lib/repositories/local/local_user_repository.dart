import '../../config/local_user.dart';
import '../../models/user.dart';
import '../user_repository.dart';

class LocalUserRepository implements UserRepository {
  LocalUserRepository();

  @override
  Future<User> getUser(String userId) async {
    if (userId == LocalUser.id) return LocalUser.user;
    return User(id: userId, name: 'Member', email: '');
  }

  @override
  Future<User> getCurrentUser() async => LocalUser.user;

  @override
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    return Future.wait(userIds.map(getUser));
  }

  @override
  Future<User> updateUser(User user) async => user;

  @override
  Future<List<User>> searchUsers(String query) async => [];

  @override
  Future<void> inviteUserByEmail(
    String email, {
    required String boardId,
  }) async {}

  @override
  Future<User?> getUserByEmail(String email) async => null;
}
