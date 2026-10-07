import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key/value abstraction so storage can be swapped (SQLite, cloud sync...) later.
abstract class StorageService {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class PrefsStorage implements StorageService {
  SharedPreferences? _prefs;
  Future<SharedPreferences> _p() async => _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async => (await _p()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await _p()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await _p()).remove(key);
  }
}

class MemoryStorage implements StorageService {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}
