import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/config/local_user.dart';
import 'package:ollie/repositories/local/local_user_repository.dart';

void main() {
  late LocalUserRepository repo;

  setUp(() {
    repo = LocalUserRepository();
  });

  group('LocalUserRepository', () {
    test('getCurrentUser returns local user', () async {
      final user = await repo.getCurrentUser();
      expect(user.id, LocalUser.id);
      expect(user.name, LocalUser.name);
    });

    test('getUser returns local user for local id', () async {
      final user = await repo.getUser(LocalUser.id);
      expect(user, LocalUser.user);
    });

    test('getUser returns placeholder for unknown ids', () async {
      final user = await repo.getUser('other-id');
      expect(user.name, 'Member');
      expect(user.id, 'other-id');
    });

    test('getUsersByIds fetches multiple users', () async {
      final users = await repo.getUsersByIds([LocalUser.id, 'other']);
      expect(users.length, 2);
      expect(users.first.id, LocalUser.id);
    });

    test('searchUsers returns empty list', () async {
      expect(await repo.searchUsers('query'), isEmpty);
    });

    test('getUserByEmail returns null', () async {
      expect(await repo.getUserByEmail('test@example.com'), isNull);
    });

    test('updateUser returns same user', () async {
      final updated = await repo.updateUser(LocalUser.user);
      expect(updated, LocalUser.user);
    });

    test('inviteUserByEmail completes without error', () async {
      await expectLater(
        repo.inviteUserByEmail('a@b.com', boardId: 'board1'),
        completes,
      );
    });
  });
}
