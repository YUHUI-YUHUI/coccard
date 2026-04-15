import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/pages/home_page.dart';
import 'app/data/character_manager.dart';
import 'app/pages/switch_character_page.dart';
import 'app/pages/settings_page.dart';
import 'app/pages/about_page.dart';
import 'app/pages/skill_page.dart';
import 'app/pages/weapon_page.dart';
import 'app/pages/reference_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final characterManager = CharacterManager(prefs: prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: characterManager),
      ],
      child: const COCCharacterApp(),
    ),
  );
}

class COCCharacterApp extends StatelessWidget {
  const COCCharacterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COC 角色卡',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/switch_character': (context) => const SwitchCharacterPage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
        '/skills': (context) => const SkillPage(),
        '/weapons': (context) => const WeaponPage(),
        '/reference': (context) => const ReferencePage(),
      },
    );
  }
}
