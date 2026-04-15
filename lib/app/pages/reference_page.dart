import 'package:flutter/material.dart';
import 'dart:math';
import '../data/coc_data.dart';

class ReferencePage extends StatefulWidget {
  const ReferencePage({super.key});

  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('参考表'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '疯狂发作'),
            Tab(text: '恐惧症'),
            Tab(text: '躁狂症'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInsanityTab(),
          _buildPhobiasTab(),
          _buildManiasTab(),
        ],
      ),
    );
  }

  Widget _buildInsanityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.purple.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('🎲 随机触发疯狂', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _rollInsanity('tmp'),
                        icon: const Icon(Icons.bolt),
                        label: const Text('即时症状'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _rollInsanity('long'),
                        icon: const Icon(Icons.hourglass_bottom),
                        label: const Text('长期症状'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('即时症状（1D10轮后消失）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: INSANITY_TMP.map((item) => ListTile(
                leading: CircleAvatar(backgroundColor: Colors.purple, child: Text('${item.id}', style: const TextStyle(color: Colors.white))),
                title: Text(item.text),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('长期症状（1D10小时后恢复）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: INSANITY_LONG.map((item) => ListTile(
                leading: CircleAvatar(backgroundColor: Colors.deepPurple, child: Text('${item.id}', style: const TextStyle(color: Colors.white))),
                title: Text(item.text),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhobiasTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: PHOBIAS.length,
      itemBuilder: (context, index) {
        final parts = PHOBIAS[index].split('：');
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.orange, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
            title: Text(parts[0]),
            subtitle: parts.length > 1 ? Text(parts[1]) : null,
          ),
        );
      },
    );
  }

  Widget _buildManiasTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MANIAS.length,
      itemBuilder: (context, index) {
        final parts = MANIAS[index].split('：');
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.teal, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
            title: Text(parts[0]),
            subtitle: parts.length > 1 ? Text(parts[1]) : null,
          ),
        );
      },
    );
  }

  void _rollInsanity(String type) {
    final roll = _random.nextInt(10) + 1;
    String title;
    String text;
    if (type == 'tmp') {
      final item = INSANITY_TMP[roll - 1];
      title = '即时症状 #$roll';
      text = item.text;
    } else {
      final item = INSANITY_LONG[roll - 1];
      title = '长期症状 #$roll';
      text = item.text;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.psychology, color: Colors.purple), const SizedBox(width: 8), Text(title)]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          const Text('⚠️ 理智值可能下降', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
    );
  }
}
