import 'package:flutter/material.dart';

class AttributeWidget extends StatelessWidget {
  final Map<String, int> attributes;
  final Function(String, int)? onEdit;

  const AttributeWidget({
    super.key,
    required this.attributes,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _attrBox('STR', '力量', attributes['力量'] ?? 0, Colors.red)),
            Expanded(child: _attrBox('CON', '体质', attributes['体质'] ?? 0, Colors.green)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _attrBox('SIZ', '体型', attributes['体型'] ?? 0, Colors.orange)),
            Expanded(child: _attrBox('DEX', '敏捷', attributes['敏捷'] ?? 0, Colors.blue)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _attrBox('APP', '外貌', attributes['外貌'] ?? 0, Colors.pink)),
            Expanded(child: _attrBox('INT', '智力', attributes['智力'] ?? 0, Colors.purple)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _attrBox('POW', '意志', attributes['意志'] ?? 0, Colors.teal)),
            Expanded(child: _attrBox('EDU', '教育', attributes['教育'] ?? 0, Colors.indigo)),
          ],
        ),
      ],
    );
  }

  Widget _attrBox(String abbr, String name, int value, Color color) {
    return GestureDetector(
      onTap: onEdit != null ? () => _showEditDialog(abbr, name, value) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(abbr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String abbr, String name, int currentValue) {
    // This is handled in home_page since it needs the manager
  }
}
