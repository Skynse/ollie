import '../models/user.dart';

/// Single local user — no accounts or sign-in.
abstract final class LocalUser {
  static const id = 'local';
  static const name = 'Me';

  static final User user = User(
    id: id,
    name: name,
    email: '',
  );
}
