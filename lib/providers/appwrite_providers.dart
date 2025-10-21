import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/config/environment.dart';

// Appwrite constants
const String databaseId = '68f0c0100009393371fd';
const String usersCollectionId = 'users';

/// Provider for the Appwrite client
final appwriteClientProvider = Provider<Client>((ref) {
  return Client()
      .setEndpoint(Environment.appwritePublicEndpoint)
      .setProject(Environment.appwriteProjectId);
});

/// Provider for the Appwrite Account service
final appwriteAccountProvider = Provider<Account>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Account(client);
});

/// Provider for the Appwrite Databases service
final appwriteDatabasesProvider = Provider<Databases>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Databases(client);
});
