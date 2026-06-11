import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/character_manager.dart';
import '../data/character.dart';
import '../data/insanity_episode.dart';
import '../data/sanity_loss_record.dart';
import '../widgets/attribute_widget.dart';
import '../widgets/derived_stats_widget.dart';
import '../widgets/dice_roller.dart';
import '../widgets/app_drawer_widget.dart';
import '../widgets/delete_character_dialog.dart';
import '../widgets/avatar_widget.dart';
import '../data/coc_data.dart';
import '../services/pdf_generator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<CharacterManager>(
          builder: (context, manager, _) {
            return Text(manager.character.name.isEmpty
                ? '新角色'
                : manager.character.name);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() => _isEditMode = !_isEditMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isEditMode ? '已进入编辑模式' : '已退出编辑模式')),
              );
            },
            tooltip: '编辑模式',
          ),
          IconButton(
            icon: const Icon(Icons.casino_outlined),
            onPressed: _isEditMode ? () => _showDiceRoller(context) : null,
            tooltip: '投骰子',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              final manager = Provider.of<CharacterManager>(
                context,
                listen: false,
              );
              PdfGenerator.generateAndPrint(manager.character);
            },
            tooltip: '导出PDF',
          ),
          Consumer<CharacterManager>(
            builder: (context, manager, _) {
              if (!manager.hasCharacters) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  final currentCharacterId = manager.character.id;
                  final currentIndex = manager.characters.indexWhere(
                    (character) => character.id == currentCharacterId,
                  );
                  showDeleteCharacterDialog(
                    context: context,
                    manager: manager,
                    index: currentIndex,
                    onDeleted: () {
                      if (!manager.hasCharacters) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      }
                    },
                  );
                },
                tooltip: '删除角色卡',
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawerWidget(),
      body: Consumer<CharacterManager>(
        builder: (context, manager, _) {
          final character = manager.character;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoCard(context, character, manager),
                const SizedBox(height: 16),
                _buildAttributeCard(context, character, manager),
                const SizedBox(height: 16),
                _buildDerivedStatsCard(context, manager.character, manager),
                const SizedBox(height: 16),
                _buildSanityCard(context, manager.character, manager),
                const SizedBox(height: 16),
                _buildWeaponsCard(context, character),
                const SizedBox(height: 16),
                _buildItemsCard(context, character, manager),
                const SizedBox(height: 16),
                _buildFinanceCard(context, character, manager),
                const SizedBox(height: 16),
                _buildBackstoryCard(context, character, manager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('基本信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showBasicInfoDialog(context, character, manager),
                ),
              ],
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AvatarWidget(size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('玩家', character.player),
                      _infoRow('职业', character.occupation.isEmpty ? '未选择' : character.occupation),
                      _infoRow('年龄', character.age),
                      _infoRow('性别', character.gender),
                      _infoRow('居住地', character.residence),
                      _infoRow('出生地', character.birthplace),
                    ],
                  ),
                ),
              ],
            ),
            if (character.appearance.isNotEmpty) ...[
              const Divider(),
              const Text('外貌', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(character.appearance),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showOccupationPicker(context, manager),
              child: Text(character.selectedOccId == null ? '选择职业' : '更换职业'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAttributeCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('属性', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_isEditMode) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.casino, color: Colors.purple, size: 20),
                        onPressed: () {
                          manager.rollAttributes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已随机投出属性')),
                          );
                        },
                        tooltip: '随机属性',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                if (_isEditMode)
                  const Icon(Icons.edit, color: Colors.green, size: 16),
              ],
            ),
            const Divider(),
            AttributeWidget(
              attributes: {
                '力量': character.str,
                '体质': character.con,
                '体型': character.siz,
                '敏捷': character.dex,
                '外貌': character.app,
                '智力': character.int_,
                '意志': character.pow,
                '教育': character.edu,
              },
              onEdit: (attr, value) => manager.updateAttribute(attr, value),
              isEditable: _isEditMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDerivedStatsCard(BuildContext context, Character character, CharacterManager manager) {
    final occRemaining = character.occupationPoint - character.occupationPointSpent;
    final intRemaining = character.interestPoint - character.interestPointSpent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('衍生属性', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            DerivedStatsWidget(
              hp: '${character.currentHp}/${character.maxHp}',
              mp: '${character.currentMp}/${character.maxMp}',
              sanity: '${character.sanity}/${character.maxSanity}',
              luck: '${character.luckDice} (${character.luck})',
              move: character.move.toString(),
              bodyBuild: character.build.toString(),
              damageBonus: character.damageBonus,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const Text('技能点数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('职业点数', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    Text(
                      '$occRemaining / ${character.occupationPoint}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('兴趣点数', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                    Text(
                      '$intRemaining / ${character.interestPoint}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('信誉范围', style: TextStyle(color: Colors.orange)),
                    Text(
                      '${character.creditMin}-${character.creditMax}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSanityCard(BuildContext context, Character character, CharacterManager manager) {
    final episodes = character.insanityEpisodes.reversed.take(3).toList();
    final losses = character.sanityLossRecords.reversed.take(3).toList();
    return Card(
      color: Colors.purple.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple),
                SizedBox(width: 8),
                Text('理智事件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSanityLossDialog(context, manager),
                    icon: const Icon(Icons.healing),
                    label: const Text('应用 SAN 损失'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showInsanityHistoryDialog(context, character),
                    icon: const Icon(Icons.history),
                    label: const Text('查看历史'),
                  ),
                ),
              ],
            ),
            if (losses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('最近 SAN 损失', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...losses.map((r) => _sanityLossTile(r)),
            ],
            if (episodes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('最近疯狂发作', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 4),
              ...episodes.map((e) => _episodeTile(e)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sanityLossTile(SanityLossRecord r) {
    final ts = '${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')} '
        '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.arrow_downward, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Text('-$r.amount', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${r.expression} → ${r.rollDetail}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(ts, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _episodeTile(InsanityEpisode e) {
    final ts = '${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')} '
        '${e.createdAt.hour.toString().padLeft(2, '0')}:${e.createdAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, size: 14, color: Colors.purple),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '#${e.symptomRoll} · ${e.durationRoll}${e.durationUnit} · ${e.symptomText}',
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(ts, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showSanityLossDialog(BuildContext context, CharacterManager manager) {
    final ctrl = TextEditingController(text: '1d6');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.healing, color: Colors.red),
              SizedBox(width: 8),
              Text('应用 SAN 损失'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入损失表达式（COC 规则）：'),
              const SizedBox(height: 8),
              const Text('1d6 / 2d6 / 1d6+1 / 1d10 / 5', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'SAN 损失表达式',
                  hintText: '1d6',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '当前 SAN：${manager.character.sanity}/${manager.character.maxSanity} · INT ${manager.character.int_}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                '注：单次损失 ≥ 5 时自动进行 INT 检定；成功则陷入临时疯狂。',
                style: TextStyle(fontSize: 11, color: Colors.deepPurple),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton.icon(
              onPressed: () {
                final expr = ctrl.text.trim();
                if (expr.isEmpty) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                _applySanityLoss(context, manager, expr);
              },
              icon: const Icon(Icons.psychology),
              label: const Text('应用'),
            ),
          ],
        );
      },
    );
  }

  void _applySanityLoss(BuildContext context, CharacterManager manager, String expression) {
    final outcome = manager.applySanityLoss(expression);
    if (!outcome.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SAN 表达式无法解析：$expression')),
      );
      return;
    }

    // 主结果行
    final lossText = '本次损失 ${outcome.loss} 点 SAN';
    String detailText = outcome.rollDetail;

    if (outcome.ranIntCheck) {
      final ic = outcome.intCheck!;
      detailText += '\nINT 检定：投出 ${ic.roll} / 目标 ${ic.target}';
      detailText += ic.success ? '（成功）' : '（失败，大脑屏蔽）';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                outcome.triggeredInsanity ? Icons.warning_amber : Icons.psychology,
                color: outcome.triggeredInsanity ? Colors.red : Colors.purple,
              ),
              const SizedBox(width: 8),
              Text(outcome.triggeredInsanity ? '疯狂发作' : 'SAN 损失已应用'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lossText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('SAN：${outcome.sanityBefore} → ${outcome.sanityAfter}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(detailText, style: const TextStyle(fontSize: 13)),
                ),
                if (outcome.episode != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '即时症状 #${outcome.episode!.symptomRoll} · 持续 ${outcome.episode!.durationRoll} ${outcome.episode!.durationUnit}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(outcome.episode!.symptomText),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          ],
        );
      },
    );
  }

  void _showInsanityHistoryDialog(BuildContext context, Character character) {
    final losses = character.sanityLossRecords.reversed.toList();
    final episodes = character.insanityEpisodes.reversed.toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.purple),
            SizedBox(width: 8),
            Text('理智事件历史'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  labelColor: Colors.purple,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'SAN 损失'),
                    Tab(text: '疯狂发作'),
                  ],
                ),
                SizedBox(
                  height: 320,
                  child: TabBarView(
                    children: [
                      _buildLossHistoryList(losses),
                      _buildEpisodeHistoryList(episodes),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _buildLossHistoryList(List<SanityLossRecord> losses) {
    if (losses.isEmpty) {
      return const Center(child: Text('暂无记录', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: losses.length,
      itemBuilder: (ctx, i) {
        final r = losses[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.arrow_downward, color: Colors.red),
          title: Text('-$r.amount · ${r.expression}'),
          subtitle: Text(r.rollDetail),
          trailing: Text(
            '${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')} '
            '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildEpisodeHistoryList(List<InsanityEpisode> episodes) {
    if (episodes.isEmpty) {
      return const Center(child: Text('暂无疯狂发作记录', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: episodes.length,
      itemBuilder: (ctx, i) {
        final e = episodes[i];
        return ListTile(
          dense: true,
          leading: Icon(
            e.triggeredInsanity ? Icons.bolt : Icons.shield,
            color: e.triggeredInsanity ? Colors.red : Colors.grey,
          ),
          title: Text('#${e.symptomRoll} · ${e.durationRoll}${e.durationUnit}'),
          subtitle: Text(
            e.symptomText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')} '
            '${e.createdAt.hour.toString().padLeft(2, '0')}:${e.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildWeaponsCard(BuildContext context, Character character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('武器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/weapons'),
                  child: const Text('管理'),
                ),
              ],
            ),
            const Divider(),
            if (character.weapons.isEmpty)
              Text('暂无武器', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            else
              ...character.weapons.take(3).map((w) => ListTile(
                dense: true,
                title: Text(w.name),
                subtitle: Text('技能 ${w.skill}% | 伤害 ${w.damage}'),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(
    BuildContext context,
    Character character,
    CharacterManager manager,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '背包物品',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '添加物品',
                  onPressed: () => _showItemDialog(context, manager),
                ),
              ],
            ),
            const Divider(),
            if (character.items.isEmpty) ...[
              Text(
                '暂无背包物品',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showItemDialog(context, manager),
                icon: const Icon(Icons.add),
                label: const Text('添加物品'),
              ),
            ] else
              ...character.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemName = item.name.trim().isEmpty ? '未命名物品' : item.name;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory_2_outlined, size: 20),
                  title: Text(itemName),
                  subtitle: Text('数量 ${item.count}'),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _showItemDialog(
                    context,
                    manager,
                    index: index,
                    item: item,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('财务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showFinanceDialog(context, character, manager),
                ),
              ],
            ),
            const Divider(),
            _infoRow('现金', '${character.cash}'),
            _infoRow('每月花费', '${character.spending}'),
            _infoRow('财产', '${character.assets}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBackstoryCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('背景故事', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showBackstoryDialog(context, character, manager),
                ),
              ],
            ),
            const Divider(),
            Text(character.backstory.isEmpty ? '暂无背景故事' : character.backstory),
          ],
        ),
      ),
    );
  }

  void _showBasicInfoDialog(BuildContext context, Character character, CharacterManager manager) {
    final nameCtrl = TextEditingController(text: character.name);
    final playerCtrl = TextEditingController(text: character.player);
    final ageCtrl = TextEditingController(text: character.age);
    final genderCtrl = TextEditingController(text: character.gender);
    final residenceCtrl = TextEditingController(text: character.residence);
    final birthplaceCtrl = TextEditingController(text: character.birthplace);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑基本信息'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '角色名')),
              TextField(controller: playerCtrl, decoration: const InputDecoration(labelText: '玩家')),
              TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: '年龄')),
              TextField(controller: genderCtrl, decoration: const InputDecoration(labelText: '性别')),
              TextField(controller: residenceCtrl, decoration: const InputDecoration(labelText: '居住地')),
              TextField(controller: birthplaceCtrl, decoration: const InputDecoration(labelText: '出生地')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              manager.updateBasicInfo(
                name: nameCtrl.text,
                player: playerCtrl.text,
                age: ageCtrl.text,
                gender: genderCtrl.text,
                residence: residenceCtrl.text,
                birthplace: birthplaceCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showOccupationPicker(BuildContext context, CharacterManager manager) {
    final scaffoldContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final searchCtrl = TextEditingController();
          String query = '';
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final q = query.toLowerCase();
              final list = q.isEmpty
                  ? OCCUPATIONS
                  : OCCUPATIONS.where((o) =>
                      o.n.toLowerCase().contains(q) ||
                      o.attr.toLowerCase().contains(q) ||
                      o.sk.toLowerCase().contains(q)).toList();
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: const Text('选择职业', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: '搜索职业（名称 / 属性公式 / 技能）...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setSheetState(() => query = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setSheetState(() => query = v.trim()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: list.isEmpty
                        ? Center(child: Text('未找到匹配的职业',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final occ = list[index];
                              return ListTile(
                                title: Text(occ.n),
                                subtitle: Text('${occ.attr} | 信用 ${occ.min}-${occ.max}'),
                                trailing: manager.character.selectedOccId == occ.id
                                    ? const Icon(Icons.check, color: Colors.blue)
                                    : null,
                                onTap: () {
                                  manager.applyOccupation(occ);
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                    SnackBar(content: Text('已选择职业: ${occ.n}')),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showItemDialog(
    BuildContext context,
    CharacterManager manager, {
    int? index,
    CharacterItem? item,
  }) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final countCtrl = TextEditingController(text: (item?.count ?? 1).toString());
    final isEditing = index != null;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? '编辑物品' : '添加物品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: !isEditing,
              decoration: const InputDecoration(labelText: '物品名称'),
            ),
            TextField(
              controller: countCtrl,
              decoration: const InputDecoration(labelText: '数量'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          if (isEditing)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                manager.deleteItem(index!);
                Navigator.pop(dialogContext);
              },
              child: const Text('删除'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入物品名称')),
                );
                return;
              }

              final newItem = CharacterItem(
                name: name,
                count: _parseItemCount(countCtrl.text),
              );
              if (isEditing) {
                manager.updateItem(index!, newItem);
              } else {
                manager.addItem(newItem);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  int _parseItemCount(String value) {
    final count = int.tryParse(value.trim()) ?? 1;
    return count < 1 ? 1 : count;
  }

  void _showFinanceDialog(BuildContext context, Character character, CharacterManager manager) {
    final cashCtrl = TextEditingController(text: character.cash.toString());
    final spendingCtrl = TextEditingController(text: character.spending.toString());
    final assetsCtrl = TextEditingController(text: character.assets.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑财务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cashCtrl, decoration: const InputDecoration(labelText: '现金'), keyboardType: TextInputType.number),
            TextField(controller: spendingCtrl, decoration: const InputDecoration(labelText: '每月花费'), keyboardType: TextInputType.number),
            TextField(controller: assetsCtrl, decoration: const InputDecoration(labelText: '财产'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              manager.updateFinance(
                cash: int.tryParse(cashCtrl.text) ?? 0,
                spending: int.tryParse(spendingCtrl.text) ?? 0,
                assets: int.tryParse(assetsCtrl.text) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showBackstoryDialog(BuildContext context, Character character, CharacterManager manager) {
    final backstoryCtrl = TextEditingController(text: character.backstory);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑背景故事'),
        content: TextField(controller: backstoryCtrl, maxLines: 5, decoration: const InputDecoration(labelText: '背景故事')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              manager.updateBackstory(backstoryCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDiceRoller(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        content: DiceRollerWidget(),
      ),
    );
  }
}
