import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'boards_provider.dart'; // userRepositoryProvider is defined here
import 'auth_provider.dart';

/// Provider for the current authenticated user
/// Fetches the custom User model from the repository using the auth user's ID
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return null;

  try {
    final repository = ref.read(userRepositoryProvider);
    return await repository.getUser(authState.user!.$id);
  } catch (e) {
    return null;
  }
});

/// Cached provider for fetching a single user by ID
/// This caches user data so we don't have to fetch it repeatedly
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repository = ref.read(userRepositoryProvider);
  return await repository.getUser(userId);
});

/// Cached provider for fetching multiple users by IDs
/// Useful for board members, card assignees, etc.
final usersProvider = FutureProvider.family<List<User>, List<String>>((
  ref,
  userIds,
) async {
  if (userIds.isEmpty) return [];

  final repository = ref.read(userRepositoryProvider);

  // Fetch all users in parallel
  final users = await Future.wait(userIds.map((id) => repository.getUser(id)));

  return users;
});
