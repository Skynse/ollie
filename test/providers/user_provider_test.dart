import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/config/local_user.dart';
import 'package:ollie/providers/user_provider.dart';

void main() {
  group('user providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('currentUserProvider returns local user', () async {
      final user = await container.read(currentUserProvider.future);
      expect(user.id, LocalUser.id);
      expect(user.name, LocalUser.name);
    });

    test('userProvider returns local user for local id', () async {
      final user = await container.read(userProvider(LocalUser.id).future);
      expect(user, LocalUser.user);
    });

    test('userProvider returns placeholder for unknown id', () async {
      final user = await container.read(userProvider('other').future);
      expect(user.name, 'Member');
    });

    test('usersProvider resolves multiple ids', () async {
      final users = await container.read(
        usersProvider([LocalUser.id, 'guest']).future,
      );
      expect(users.length, 2);
      expect(users.first.id, LocalUser.id);
      expect(users.last.id, 'guest');
    });

    test('usersProvider returns empty for empty input', () async {
      final users = await container.read(usersProvider([]).future);
      expect(users, isEmpty);
    });
  });
}
