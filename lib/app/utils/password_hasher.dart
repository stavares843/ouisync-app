import 'package:ouisync_plugin/ouisync_plugin.dart';

// This class exists mainly to avoid passing the ouisync Session througout the
// code where only it's password hashing functionality is needed.
class PasswordHasher {
  final Session _ouisyncSession;

  PasswordHasher(this._ouisyncSession);

  Future<LocalSecretKeyAndSalt> hashPassword(
    LocalPassword password, [
    PasswordSalt? salt,
  ]) async {
    salt = salt ?? PasswordSalt.random();
    final key = await _ouisyncSession.deriveLocalSecretKey(password, salt);

    return LocalSecretKeyAndSalt(key, salt);
  }
}
