import 'package:flutter/material.dart';

class AttributeWidget extends StatelessWidget {
  final Map<String, int> attributes;
  final Function(String, int)? onEdit;
  final bool isEditable;

  const AttributeWidget({
    super.key,
    required this.attributes,
    this.onEdit,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _attrBox(context, 'STR', '力量', attributes['力量'] ?? 0, Colors.red)),
            Expanded(child: _attrBox(context, 'CON', '体质', attributes['体质'] ?? 0, Colors.green)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _attrBox(context, 'SIZ', '体型', attributes['体型'] ?? 0, Colors.orange)),
            Expanded(child: _attrBox(context, 'DEX', '敏捷', attributes['敏捷'] ?? 0, Colors.blue)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _attrBox(context, 'APP', '外貌', attributes['外貌'] ?? 0, Colors.pink)),
            Expanded(child: _attrBox(context, 'INT', '智力', attributes['智力'] ?? 0, Colors.purple)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _attrBox(context, 'POW', '意志', attributes['意志'] ?? 0, Colors.teal)),
            Expanded(child: _attrBox(context, 'EDU', '教育', attributes['教育'] ?? 0, Colors.indigo)),
          ],
        ),
      ],
    );
  }

  Widget _attrBox(BuildContext context, String abbr, String name, int value, Color color) {
    return GestureDetector(
      onTap: (isEditable && onEdit != null) ? () => _showEditDialog(context, abbr, name, value) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isEditable ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(abbr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                if (isEditable) Icon(Icons.edit, size: 12, color: color.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String abbr, String name, int currentValue) {
    if (onEdit == null) return;
    final ctrl = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 $name'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '$name ($abbr)',
            hintText: '输入 1-99 的值',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(ctrl.text);
              if (value != null && value >= 1 && value <= 99) {
                onEdit!(name, value);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
