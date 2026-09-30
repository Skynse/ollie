import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/local_user.dart';
import '../models/user.dart';

final currentUserProvider = FutureProvider<User>((ref) async {
  return LocalUser.user;
});

final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  if (userId == LocalUser.id) return LocalUser.user;
  return User(id: userId, name: 'Member', email: '');
});

final usersProvider = FutureProvider.family<List<User>, List<String>>((
  ref,
  userIds,
) async {
  if (userIds.isEmpty) return [];
  return userIds
      .map(
        (id) => id == LocalUser.id
            ? LocalUser.user
            : User(id: id, name: 'Member', email: ''),
      )
      .toList();
});
