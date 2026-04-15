import 'dart:math';
import 'package:flutter/material.dart';

class DiceRollerWidget extends StatefulWidget {
  const DiceRollerWidget({super.key});
  @override
  State<DiceRollerWidget> createState() => _DiceRollerWidgetState();
}

class _DiceRollerWidgetState extends State<DiceRollerWidget> {
  final Random _random = Random();
  int _d100Result = 0;
  int _d6Result = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎲 投骰子系统', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const Text('D100 技能检定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _rollD100, icon: const Icon(Icons.casino), label: const Text('投掷 D100'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
          if (_d100Result > 0) ...[const SizedBox(height: 16), Text('$_d100Result', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold))],
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const Text('3D6 属性生成', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _roll3D6, icon: const Icon(Icons.casino), label: const Text('投掷 3D6'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16))),
          if (_d6Result > 0) ...[const SizedBox(height: 16), Text('$_d6Result (×5 = ${_d6Result * 5})', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))],
        ]))),
      ]),
    );
  }

  void _rollD100() {
    setState(() => _d100Result = _random.nextInt(100) + 1);
  }

  void _roll3D6() {
    setState(() => _d6Result = _random.nextInt(6) + 1 + _random.nextInt(6) + 1 + _random.nextInt(6) + 1);
  }
}
