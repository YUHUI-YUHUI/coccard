import 'package:flutter/material.dart';

class DerivedStatsWidget extends StatelessWidget {
  final String hp, mp, sanity, luck, move, bodyBuild, damageBonus;
  const DerivedStatsWidget({super.key, required this.hp, required this.mp, required this.sanity, required this.luck, required this.move, required this.bodyBuild, required this.damageBonus});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [Expanded(child: _statBox('HP', hp, Icons.favorite, Colors.red)), Expanded(child: _statBox('MP', mp, Icons.auto_awesome, Colors.blue))]),
      Row(children: [Expanded(child: _statBox('SAN', sanity, Icons.psychology, Colors.purple)), Expanded(child: _statBox('幸运', luck, Icons.star, Colors.amber))]),
      Row(children: [Expanded(child: _statBox('移动', move, Icons.directions_run, Colors.green)), Expanded(child: _statBox('体型', bodyBuild, Icons.accessibility, Colors.orange))]),
      Row(children: [
        Expanded(child: Container(
          margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
          child: Column(children: [const Text('伤害加成', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(damageBonus, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red))]),
        )),
        const Expanded(child: SizedBox()),
      ]),
    ]);
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [Icon(icon, color: color, size: 24), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: color)), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))])]),
    );
  }
}
