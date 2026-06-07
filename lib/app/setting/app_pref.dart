import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../data/check_rule.dart';
import 'secrets.dart';

class AppPreferences {
  final SharedPreferences _prefs;
  static const String _lastCharacterIdKey = 'last_character_id';
  static const String _darkModeEnabledKey = 'dark_mode_enabled';
  static const String _checkRuleProfileKey = 'check_rule_profile';

  AppPreferences(this._prefs);

  /// 取检定规则配置。任何异常或缺失都回退到 COC7 默认。
  CheckRuleProfile getCheckRuleProfile() {
    final raw = _prefs.getString(_checkRuleProfileKey);
    if (raw == null || raw.isEmpty) return CheckRuleProfile.coc7Default;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return CheckRuleProfile.fromJson(json);
      }
    } catch (_) {
      // 落入默认
    }
    return CheckRuleProfile.coc7Default;
  }

  Future<void> setCheckRuleProfile(CheckRuleProfile profile) async {
    await _prefs.setString(
      _checkRuleProfileKey,
      jsonEncode(profile.toJson()),
    );
  }

  // 获取最后使用的角色ID
  int? getLastCharacterId() {
    return _prefs.getInt(_lastCharacterIdKey);
  }

  // 保存最后使用的角色ID
  Future<void> saveLastCharacterId(int id) async {
    await _prefs.setInt(_lastCharacterIdKey, id);
  }

  bool getDarkModeEnabled() {
    return _prefs.getBool(_darkModeEnabledKey) ?? false;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    await _prefs.setBool(_darkModeEnabledKey, enabled);
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

  // ===== 图像生成（头像）配置 =====
  static const String _imageProviderKey = 'image_provider';
  static const String _imageApiKeyKey = 'image_api_key';
  static const String _imageModelKey = 'image_model';

  /// 取 provider 字符串（对应 ImageGenProvider.name）。默认 stub。
  String getImageProvider() {
    return _prefs.getString(_imageProviderKey) ?? 'stub';
  }

  Future<void> setImageProvider(String name) async {
    await _prefs.setString(_imageProviderKey, name);
  }

  String getImageApiKey() {
    return _prefs.getString(_imageApiKeyKey) ?? '';
  }

  Future<void> setImageApiKey(String key) async {
    await _prefs.setString(_imageApiKeyKey, key);
  }

  String getImageModel() {
    return _prefs.getString(_imageModelKey) ?? '';
  }

  Future<void> setImageModel(String model) async {
    await _prefs.setString(_imageModelKey, model);
  }
}
