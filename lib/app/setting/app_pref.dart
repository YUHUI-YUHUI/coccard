import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  final SharedPreferences _prefs;
  static const String _lastCharacterIdKey = 'last_character_id';

  AppPreferences(this._prefs);

  // 获取最后使用的角色ID
  int? getLastCharacterId() {
    return _prefs.getInt(_lastCharacterIdKey);
  }

  // 保存最后使用的角色ID
  Future<void> saveLastCharacterId(int id) async {
    await _prefs.setInt(_lastCharacterIdKey, id);
  }

  static const String _deepseekApiKeyKey = 'deepseek_api_key';

  String getDeepseekApiKey() => _prefs.getString(_deepseekApiKeyKey) ?? '';

  Future<void> setDeepseekApiKey(String key) async {
    await _prefs.setString(_deepseekApiKeyKey, key);
  }
}
