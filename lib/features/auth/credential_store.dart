import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Credentials {
  const Credentials({required this.username, required this.password});
  final String username;
  final String password;
}

class CredentialStore {
  static const _kUsername = 'cck_username';
  static const _kPassword = 'cck_password';

  final _storage = const FlutterSecureStorage();

  Future<Credentials?> load() async {
    final username = await _storage.read(key: _kUsername);
    final password = await _storage.read(key: _kPassword);
    if (username == null || password == null) return null;
    return Credentials(username: username, password: password);
  }

  Future<void> save(Credentials credentials) async {
    await _storage.write(key: _kUsername, value: credentials.username);
    await _storage.write(key: _kPassword, value: credentials.password);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
