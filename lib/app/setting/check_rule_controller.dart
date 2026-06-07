import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/check_rule.dart';
import 'app_pref.dart';

/// 全局 D100 检定规则状态。通过 [Provider] 暴露给 SkillPage、骰点页等使用。
class CheckRuleController extends ChangeNotifier {
  final AppPreferences _appPreferences;
  CheckRuleProfile _profile;

  CheckRuleController({required SharedPreferences prefs})
      : _appPreferences = AppPreferences(prefs),
        _profile = AppPreferences(prefs).getCheckRuleProfile();

  CheckRuleProfile get profile => _profile;

  Future<void> setProfile(CheckRuleProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _appPreferences.setCheckRuleProfile(profile);
  }
}
