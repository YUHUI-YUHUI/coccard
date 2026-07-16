import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/pages/home_page.dart';
import 'app/pages/start_page.dart';
import 'app/data/character_manager.dart';
import 'app/pages/switch_character_page.dart';
import 'app/pages/character_creation_page.dart';
import 'app/pages/settings_page.dart';
import 'app/pages/about_page.dart';
import 'app/pages/skill_page.dart';
import 'app/pages/skill_growth_page.dart';
import 'app/pages/skill_check_log_page.dart';
import 'app/pages/weapon_page.dart';
import 'app/pages/reference_page.dart';
import 'app/pages/ai_character_page.dart';
import 'app/pages/rulebook_reader_page.dart';
import 'app/pages/character_archive_page.dart';
import 'app/setting/check_rule_controller.dart';
import 'app/setting/combat_controller.dart';
import 'app/setting/dice_history_controller.dart';
import 'app/setting/theme_controller.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final characterManager = CharacterManager(prefs: prefs);
  final themeController = ThemeController(prefs: prefs);
  final checkRuleController = CheckRuleController(prefs: prefs);
  final diceHistoryController = DiceHistoryController(prefs: prefs);
  final combatController = CombatController(prefs: prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: characterManager),
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: checkRuleController),
        ChangeNotifierProvider.value(value: diceHistoryController),
        ChangeNotifierProvider.value(value: combatController),
      ],
      child: const COCCharacterApp(),
    ),
  );
}

class COCCharacterApp extends StatelessWidget {
  const COCCharacterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          title: 'COC 角色卡',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.themeMode,
          routes: {
            '/': (context) => const StartPage(),
            '/home': (context) => const HomePage(),
            '/switch_character': (context) => const SwitchCharacterPage(),
            '/character_archive': (context) => const CharacterArchivePage(),
            '/create_character': (context) => const CharacterCreationPage(),
            '/settings': (context) => const SettingsPage(),
            '/about': (context) => const AboutPage(),
            '/skills': (context) => const SkillPage(),
            '/skill_growth': (context) => const SkillGrowthPage(),
            '/skill_check_log': (context) => const SkillCheckLogPage(),
            '/weapons': (context) => const WeaponPage(),
            '/reference': (context) => const ReferencePage(),
            '/ai_character': (context) => const AiCharacterPage(),
            '/rulebook': (context) => const RulebookReaderPage(),
          },
        );
      },
    );
  }
}
