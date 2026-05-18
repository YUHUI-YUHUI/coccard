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

  // AI Provider: 0=deepseek, 1=mimo
  static const String _aiProviderKey = 'ai_provider';
  // API Keys per provider
  static const String _deepseekApiKeyKey = 'deepseek_api_key';
  static const String _mimoApiKeyKey = 'mimo_api_key';

  int get aiProviderIndex => _prefs.getInt(_aiProviderKey) ?? 0;

  Future<void> setAiProviderIndex(int index) async {
    await _prefs.setInt(_aiProviderKey, index);
  }

  String getDeepseekApiKey() => _prefs.getString(_deepseekApiKeyKey) ?? '';

  Future<void> setDeepseekApiKey(String key) async {
    await _prefs.setString(_deepseekApiKeyKey, key);
  }

  String getMimoApiKey() => _prefs.getString(_mimoApiKeyKey) ?? '';

  Future<void> setMimoApiKey(String key) async {
    await _prefs.setString(_mimoApiKeyKey, key);
  }
}
