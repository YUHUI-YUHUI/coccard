import 'package:shared_preferences/shared_preferences.dart';
import 'secrets.dart';

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
  static const String _defaultDeepseekApiKey = Secrets.defaultDeepseekApiKey;

  String getDeepseekApiKey() {
    final saved = _prefs.getString(_deepseekApiKeyKey)?.trim();
    if (saved == null || saved.isEmpty) return _defaultDeepseekApiKey;
    // 防御：旧版本可能误把 URL 等非法值保存为 key，自动回退默认
    if (!saved.startsWith('sk-')) return _defaultDeepseekApiKey;
    return saved;
  }

  Future<void> setDeepseekApiKey(String key) async {
    await _prefs.setString(_deepseekApiKeyKey, key);
  }
}
