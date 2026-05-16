import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../data/character.dart';

class PdfGenerator {
  static pw.Font? _chineseFont;
  static pw.Font? _chineseBoldFont;
  static bool _fontsLoaded = false;

  static bool testMode = false;
  static String testAssetsRoot = '';

  static void reset() {
    _chineseFont = null;
    _chineseBoldFont = null;
    _fontsLoaded = false;
  }

  // ===== 技能分类 =====
  static const _investigative = ['信用评级', '人类学', '估价', '考古学', '图书馆使用', '侦查', '法律', '医学', '会计'];
  static const _social = ['取悦', '说服', '话术', '恐吓', '魅惑'];
  static const _combat = ['格斗', '格斗(斗殴)', '射击', '射击(手枪)', '射击(步枪)', '闪避', '急救'];
  static const _physical = ['攀爬', '跳跃', '潜行', '游泳', '投掷'];
  static const _knowledge = ['神秘学', '历史', '博物学', '科学', '导航'];
  static const _craft = ['锁匠', '伪装', '电子学', '电气维修', '机械维修'];
  static const _manipulation = ['生存', '驾驶', '汽车驾驶', '骑术', '追踪', '操作重型机械'];

  static String _skillCategory(String skill) {
    if (_investigative.contains(skill)) return 'investigative';
    if (_social.contains(skill)) return 'social';
    if (_combat.contains(skill)) return 'combat';
    if (_physical.contains(skill)) return 'physical';
    if (_knowledge.contains(skill)) return 'knowledge';
    if (_craft.contains(skill)) return 'craft';
    if (_manipulation.contains(skill)) return 'manipulation';
    if (skill.contains('语言') || skill.contains('母语') || skill.contains('外语')) return 'social';
    if (skill.contains('艺术') || skill.contains('手艺')) return 'craft';
    return 'other';
  }

  static List<MapEntry<String, int>> _sortedSkills(Map<String, int> skills) {
    final cats = <String, List<MapEntry<String, int>>>{
      'investigative': [], 'social': [], 'combat': [],
      'physical': [], 'knowledge': [], 'craft': [],
      'manipulation': [], 'other': [],
    };
    for (final e in skills.entries) {
      cats[_skillCategory(e.key)]!.add(e);
    }
    final result = <MapEntry<String, int>>[];
    for (final cat in ['investigative', 'social', 'combat', 'physical', 'knowledge', 'craft', 'manipulation', 'other']) {
      result.addAll(cats[cat]!);
    }
    return result;
  }

  // ===== 公共 API =====

  static Future<void> generateAndPrint(Character character) async {
    final pdf = pw.Document();
    await _loadFonts();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage1(character),
    ));
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage2(character),
    ));
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '${character.name.isEmpty ? "新角色" : character.name}_角色卡.pdf',
    );
  }

  static Future<void> sharePdf(Character character) async {
    final pdf = pw.Document();
    await _loadFonts();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage1(character),
    ));
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage2(character),
    ));
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${character.name.isEmpty ? "新角色" : character.name}_角色卡.pdf',
    );
  }

  static Future<Uint8List> generatePdfBytes(Character character) async {
    final pdf = pw.Document();
    await _loadFonts();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage1(character),
    ));
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage2(character),
    ));
    return pdf.save();
  }

  static Future<Uint8List> generateFillablePdfBytes(Character character) async {
    final pdf = pw.Document();
    await _loadFonts();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage1(character, fillable: true),
    ));
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) => _buildPage2(character, fillable: true),
    ));
    return pdf.save();
  }

  static Future<void> generateFillablePdfFile(Character character, String outputPath) async {
    final bytes = await generateFillablePdfBytes(character);
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
  }

  // ==================== Page 1 ====================

  static pw.Widget _buildPage1(Character character, {bool fillable = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 标题
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.symmetric(vertical: 6),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
          child: pw.Text('克苏鲁的呼唤 第七版 调查员数据表', style: _titleStyle()),
        ),
        pw.SizedBox(height: 6),

        // 基本信息
        _buildBasicInfoSection(character, fillable: fillable),
        pw.SizedBox(height: 6),

        // 属性 + 衍生属性
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(flex: 3, child: _buildAttributesSection(character, fillable: fillable)),
            pw.SizedBox(width: 6),
            pw.Expanded(flex: 2, child: _buildDerivedStatsSection(character, fillable: fillable)),
          ],
        ),
        pw.SizedBox(height: 6),

        // 技能
        pw.Expanded(child: _buildSkillsSection(character)),
      ],
    );
  }

  // ----- 基本信息 -----
  static pw.Widget _buildBasicInfoSection(Character character, {bool fillable = false}) {
    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
        columnWidths: {
          0: pw.FixedColumnWidth(50),
          1: pw.FlexColumnWidth(),
          2: pw.FixedColumnWidth(50),
          3: pw.FlexColumnWidth(),
          4: pw.FixedColumnWidth(35),
          5: pw.FixedColumnWidth(40),
          6: pw.FixedColumnWidth(35),
          7: pw.FixedColumnWidth(40),
        },
        children: [
          pw.TableRow(children: [
            _labelCell('姓名'), _valueCell(character.name, fillable: fillable, fieldName: 'name'),
            _labelCell('玩家'), _valueCell(character.player, fillable: fillable, fieldName: 'player'),
            _labelCell('年龄'), _valueCell(character.age, fillable: fillable, fieldName: 'age'),
            _labelCell('性别'), _valueCell(character.gender, fillable: fillable, fieldName: 'gender'),
          ]),
          pw.TableRow(children: [
            _labelCell('职业'), _valueCell(character.occupation, fillable: fillable, fieldName: 'occupation'),
            _labelCell(''), _valueCell('', fillable: false),
            _labelCell('居住地'), _valueCell(character.residence, fillable: fillable, fieldName: 'residence'),
            _labelCell('出生地'), _valueCell(character.birthplace, fillable: fillable, fieldName: 'birthplace'),
          ]),
        ],
      ),
    );
  }

  // ----- 属性区 -----
  static pw.Widget _buildAttributesSection(Character character, {bool fillable = false}) {
    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('属性'),
          pw.Table(
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            columnWidths: {
              0: pw.FixedColumnWidth(28),
              1: pw.FixedColumnWidth(30),
              2: pw.FixedColumnWidth(22),
              3: pw.FixedColumnWidth(22),
              4: pw.FixedColumnWidth(6),  // spacer
              5: pw.FixedColumnWidth(28),
              6: pw.FixedColumnWidth(30),
              7: pw.FixedColumnWidth(22),
              8: pw.FixedColumnWidth(22),
            },
            children: [
              // header
              pw.TableRow(children: [
                _headerCell(''), _headerCell('值'), _headerCell('½'), _headerCell('⅕'),
                pw.SizedBox(),
                _headerCell(''), _headerCell('值'), _headerCell('½'), _headerCell('⅕'),
              ]),
              // data rows
              _attributeRow('STR', '力量', character.str, 'CON', '体质', character.con, fillable: fillable),
              _attributeRow('SIZ', '体型', character.siz, 'DEX', '敏捷', character.dex, fillable: fillable),
              _attributeRow('APP', '外貌', character.app, 'INT', '智力', character.int_, fillable: fillable),
              _attributeRow('POW', '意志', character.pow, 'EDU', '教育', character.edu, fillable: fillable),
            ],
          ),
        ],
      ),
    );
  }

  static pw.TableRow _attributeRow(
    String abbr1, String cn1, int val1,
    String abbr2, String cn2, int val2,
    {bool fillable = false}
  ) {
    return pw.TableRow(children: [
      _attrLabelCell(abbr1, cn1),
      _attrValueCell(val1, fillable: fillable, fieldName: abbr1.toLowerCase()),
      _attrSubCell((val1 / 2).floor()),
      _attrSubCell((val1 / 5).floor()),
      pw.SizedBox(),
      _attrLabelCell(abbr2, cn2),
      _attrValueCell(val2, fillable: fillable, fieldName: abbr2.toLowerCase()),
      _attrSubCell((val2 / 2).floor()),
      _attrSubCell((val2 / 5).floor()),
    ]);
  }

  // ----- 衍生属性区 -----
  static pw.Widget _buildDerivedStatsSection(Character character, {bool fillable = false}) {
    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('衍生属性'),
          pw.Table(
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            columnWidths: {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                _statBox('HP', '${character.currentHp}', sub: '/${character.maxHp}', fillable: fillable, fieldName: 'curHp'),
                _statBox('MP', '${character.currentMp}', sub: '/${character.maxMp}', fillable: fillable, fieldName: 'curMp'),
              ]),
              pw.TableRow(children: [
                _statBox('理智', '${character.sanity}', sub: '/${character.maxSanity}', fillable: fillable, fieldName: 'sanity'),
                _statBox('幸运', '${character.luck}', fillable: fillable, fieldName: 'luck'),
              ]),
              pw.TableRow(children: [
                _statBox('移动力', '${character.move}', fillable: fillable, fieldName: 'move'),
                _statBox('伤害加值', character.damageBonus, fillable: fillable, fieldName: 'damageBonus'),
              ]),
              pw.TableRow(children: [
                _statBox('体格', '${character.build}', fillable: fillable, fieldName: 'build'),
                _statBox('信誉', '${character.creditMin}-${character.creditMax}', fillable: fillable, fieldName: 'credit'),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ----- 技能区 -----
  static pw.Widget _buildSkillsSection(Character character) {
    final sorted = _sortedSkills(character.skills);
    final mid = (sorted.length + 1) ~/ 2;
    final leftSkills = sorted.sublist(0, mid);
    final rightSkills = sorted.length > mid ? sorted.sublist(mid) : <MapEntry<String, int>>[];

    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('技能'),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _skillColumn(leftSkills)),
                pw.Container(width: 0.5, color: PdfColors.grey400),
                pw.Expanded(child: _skillColumn(rightSkills)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _skillColumn(List<MapEntry<String, int>> skills) {
    if (skills.isEmpty) return pw.SizedBox();
    return pw.Table(
      columnWidths: {
        0: pw.FlexColumnWidth(),
        1: pw.FixedColumnWidth(40),
      },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(width: 0.3, color: PdfColors.grey300),
      ),
      children: [
        for (final skill in skills)
          pw.TableRow(children: [
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              child: pw.Text(skill.key, style: _smallStyle()),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              child: pw.Text('${skill.value}%', style: _smallStyle(), textAlign: pw.TextAlign.right),
            ),
          ]),
      ],
    );
  }

  // ==================== Page 2 ====================

  static pw.Widget _buildPage2(Character character, {bool fillable = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 背景故事
        _buildBackstorySection(character, fillable: fillable),
        pw.SizedBox(height: 6),

        // 武器
        _buildWeaponsSection(character, fillable: fillable),
        pw.SizedBox(height: 6),

        // 财务 + 技能点
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildFinanceSection(character, fillable: fillable)),
            pw.SizedBox(width: 6),
            pw.Expanded(child: _buildSkillPointsSection(character, fillable: fillable)),
          ],
        ),
        pw.SizedBox(height: 6),

        // 笔记
        pw.Expanded(child: _buildNotesSection(character, fillable: fillable)),
      ],
    );
  }

  // ----- 背景故事 -----
  static pw.Widget _buildBackstorySection(Character character, {bool fillable = false}) {
    return pw.Container(
      height: 200,
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('背景故事'),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: fillable
                  ? pw.TextField(
                      name: 'backstory',
                      defaultValue: character.backstory,
                      width: double.infinity,
                      height: 170,
                      textStyle: _bodyStyle(),
                    )
                  : pw.Text(character.backstory, style: _bodyStyle()),
            ),
          ),
        ],
      ),
    );
  }

  // ----- 武器 -----
  static pw.Widget _buildWeaponsSection(Character character, {bool fillable = false}) {
    final rows = <pw.TableRow>[
      pw.TableRow(children: [
        _headerCell('武器'), _headerCell('技能%'), _headerCell('伤害'),
        _headerCell('射程'), _headerCell('攻击'), _headerCell('弹药'), _headerCell('故障'),
      ]),
    ];

    for (int i = 0; i < character.weapons.length && i < 8; i++) {
      final w = character.weapons[i];
      rows.add(pw.TableRow(children: [
        _bodyCell(w.name),
        _bodyCell('${w.skill}%', align: pw.TextAlign.center),
        _bodyCell(w.damage, align: pw.TextAlign.center),
        _bodyCell(w.range, align: pw.TextAlign.center),
        _bodyCell(w.attacks, align: pw.TextAlign.center),
        _bodyCell(w.ammo, align: pw.TextAlign.center),
        _bodyCell(w.malfunction, align: pw.TextAlign.center),
      ]));
    }

    // 填充空行保持高度一致
    for (int i = rows.length; i < 4; i++) {
      rows.add(pw.TableRow(children: [
        _bodyCell(''), _bodyCell(''), _bodyCell(''),
        _bodyCell(''), _bodyCell(''), _bodyCell(''), _bodyCell(''),
      ]));
    }

    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('武器'),
          pw.Table(
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FixedColumnWidth(50),
              2: pw.FixedColumnWidth(50),
              3: pw.FixedColumnWidth(50),
              4: pw.FixedColumnWidth(40),
              5: pw.FixedColumnWidth(40),
              6: pw.FixedColumnWidth(40),
            },
            children: rows,
          ),
        ],
      ),
    );
  }

  // ----- 财务 -----
  static pw.Widget _buildFinanceSection(Character character, {bool fillable = false}) {
    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('财务状况'),
          pw.Table(
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            columnWidths: {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                _labelCell('信誉评级'), _valueCell('${character.creditMin}-${character.creditMax}', fillable: fillable, fieldName: 'credit'),
              ]),
              pw.TableRow(children: [
                _labelCell('现金'), _valueCell('${character.cash}', fillable: fillable, fieldName: 'cash'),
              ]),
              pw.TableRow(children: [
                _labelCell('每月花费'), _valueCell('${character.spending}', fillable: fillable, fieldName: 'spending'),
              ]),
              pw.TableRow(children: [
                _labelCell('财产'), _valueCell('${character.assets}', fillable: fillable, fieldName: 'assets'),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ----- 技能点 -----
  static pw.Widget _buildSkillPointsSection(Character character, {bool fillable = false}) {
    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('技能点'),
          pw.Table(
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            columnWidths: {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                _labelCell('本职技能点'), _valueCell('${character.occupationPointSpent}/${character.occupationPoint}', fillable: fillable, fieldName: 'occPoint'),
              ]),
              pw.TableRow(children: [
                _labelCell('兴趣技能点'), _valueCell('${character.interestPointSpent}/${character.interestPoint}', fillable: fillable, fieldName: 'intPoint'),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ----- 笔记 -----
  static pw.Widget _buildNotesSection(Character character, {bool fillable = false}) {
    return pw.Container(
      decoration: _boxDecoration(),
      child: pw.Column(
        children: [
          _sectionHeader('笔记'),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: fillable
                  ? pw.TextField(
                      name: 'notes',
                      defaultValue: character.notes,
                      width: double.infinity,
                      height: double.infinity,
                      textStyle: _bodyStyle(),
                    )
                  : pw.Text(character.notes, style: _bodyStyle()),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Cell Helpers ====================

  static pw.BoxDecoration _boxDecoration() {
    return pw.BoxDecoration(border: pw.Border.fromBorderSide(pw.BorderSide(width: 0.5)));
  }

  static pw.Widget _sectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      color: PdfColors.grey200,
      child: pw.Text(title, style: _headerStyle()),
    );
  }

  static pw.Widget _labelCell(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(text, style: _labelStyle()),
    );
  }

  static pw.Widget _valueCell(String text, {bool fillable = false, String fieldName = ''}) {
    if (fillable && fieldName.isNotEmpty) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: pw.TextField(
          name: fieldName,
          defaultValue: text,
          width: 80,
          height: 14,
          textStyle: _bodyStyle(),
        ),
      );
    }
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(text, style: _bodyStyle()),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Text(text, style: _smallBoldStyle(), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _bodyCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(text, style: _smallStyle(), textAlign: align),
    );
  }

  static pw.Widget _attrLabelCell(String abbr, String cn) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(abbr, style: _smallBoldStyle()),
          pw.Text(cn, style: pw.TextStyle(font: _chineseFont, fontSize: 5)),
        ],
      ),
    );
  }

  static pw.Widget _attrValueCell(int value, {bool fillable = false, String fieldName = ''}) {
    if (fillable && fieldName.isNotEmpty) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        child: pw.TextField(
          name: fieldName,
          defaultValue: '$value',
          width: 28,
          height: 14,
          textStyle: _bodyStyle(),
        ),
      );
    }
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Text('$value', style: _bodyStyle(), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _attrSubCell(int value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Text('$value', style: _smallStyle(), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _statBox(String label, String value, {String? sub, bool fillable = false, String fieldName = ''}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(3),
      child: pw.Column(
        children: [
          pw.Text(label, style: _labelStyle(), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 2),
          if (fillable && fieldName.isNotEmpty)
            pw.TextField(
              name: fieldName,
              defaultValue: value,
              width: 50,
              height: 16,
              textStyle: _bodyStyle(),
            )
          else
            pw.Text(value, style: _bodyStyle(), textAlign: pw.TextAlign.center),
          if (sub != null) ...[
            pw.SizedBox(height: 1),
            pw.Text(sub, style: _smallStyle(), textAlign: pw.TextAlign.center),
          ],
        ],
      ),
    );
  }

  // ==================== Font & Style Helpers ====================

  static pw.TextStyle _titleStyle() => pw.TextStyle(font: _chineseBoldFont, fontSize: 14);
  static pw.TextStyle _headerStyle() => pw.TextStyle(font: _chineseBoldFont, fontSize: 10);
  static pw.TextStyle _bodyStyle() => pw.TextStyle(font: _chineseFont, fontSize: 8);
  static pw.TextStyle _labelStyle() => pw.TextStyle(font: _chineseFont, fontSize: 7);
  static pw.TextStyle _smallStyle() => pw.TextStyle(font: _chineseFont, fontSize: 6);
  static pw.TextStyle _smallBoldStyle() => pw.TextStyle(font: _chineseBoldFont, fontSize: 6);

  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    try {
      if (testMode) {
        final basePath = '$testAssetsRoot/assets/Noto_Sans_SC/static';
        final regFile = File('$basePath/NotoSansSC-Regular.ttf');
        final boldFile = File('$basePath/NotoSansSC-Bold.ttf');
        if (await regFile.exists()) {
          _chineseFont = pw.Font.ttf(regFile.readAsBytesSync().buffer.asByteData());
        }
        if (await boldFile.exists()) {
          _chineseBoldFont = pw.Font.ttf(boldFile.readAsBytesSync().buffer.asByteData());
        }
      } else {
        final regData = await rootBundle.load('assets/Noto_Sans_SC/static/NotoSansSC-Regular.ttf');
        _chineseFont = pw.Font.ttf(regData);
        final boldData = await rootBundle.load('assets/Noto_Sans_SC/static/NotoSansSC-Bold.ttf');
        _chineseBoldFont = pw.Font.ttf(boldData);
      }
    } catch (e) {
      debugPrint('[PdfGenerator] 字体加载失败: $e');
    }
    _fontsLoaded = true;
  }
}
