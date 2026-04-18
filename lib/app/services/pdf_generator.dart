import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../data/character.dart';

class PdfGenerator {
  static pw.Font? _chineseFont;
  static bool _fontsLoaded = false;

  static Future<void> generateAndPrint(Character character) async {
    final pdf = pw.Document();
    await _loadFonts();
    final bg1 = await _loadImage('assets/1920sCha_01.png');
    final bg2 = await _loadImage('assets/1920sCha_02.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildPage1(character, bg1, bg2 == null),
      ),
    );

    if (bg2 != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildPage2(character, bg2),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '${character.name.isEmpty ? "新角色" : character.name}_角色卡.pdf',
    );
  }

  static Future<void> sharePdf(Character character) async {
    final pdf = pw.Document();
    await _loadFonts();
    final bg1 = await _loadImage('assets/1920sCha_01.png');
    final bg2 = await _loadImage('assets/1920sCha_02.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildPage1(character, bg1, bg2 == null),
      ),
    );

    if (bg2 != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildPage2(character, bg2),
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${character.name.isEmpty ? "新角色" : character.name}_角色卡.pdf',
    );
  }

  // ==================== 可填写表单 PDF ====================
  static Future<Uint8List> generateFillablePdfBytes(Character character) async {
    final pdf = pw.Document();
    await _loadFonts();
    final bg1 = await _loadImage('assets/1920sCha_01.png');
    final bg2 = await _loadImage('assets/1920sCha_02.png');

    final formFields = _buildFormFieldsData(character);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildFillablePage1(character, bg1, bg2 == null, formFields),
      ),
    );

    if (bg2 != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildFillablePage2(character, bg2, formFields),
        ),
      );
    }

    return pdf.save();
  }

  static Future<void> generateFillablePdfFile(Character character, String outputPath) async {
    final bytes = await generateFillablePdfBytes(character);
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
  }

  static Map<String, String> _buildFormFieldsData(Character character) {
    return {
      // 第一页字段
      'name': character.name,
      'player': character.player,
      'occupation': character.occupation,
      'age': character.age,
      'gender': character.gender,
      'residence': character.residence,
      'birthplace': character.birthplace,
      'str': '${character.str}',
      'con': '${character.con}',
      'siz': '${character.siz}',
      'dex': '${character.dex}',
      'app': '${character.app}',
      'int': '${character.int_}',
      'pow': '${character.pow}',
      'edu': '${character.edu}',
      'hp': '${character.currentHp}/${character.maxHp}',
      'mp': '${character.currentMp}/${character.maxMp}',
      'sanity': '${character.sanity}/${character.maxSanity}',
      'luck': '${character.luck}',
      'move': '${character.move}',
      'build': '${character.build}',
      'damageBonus': character.damageBonus,
      // 第二页字段
      'cash': '${character.cash}',
      'spending': '${character.spending}',
      'assets': '${character.assets}',
      'backstory': character.backstory,
    };
  }

  static pw.Widget _buildFillablePage1(Character character, Uint8List? bg1, bool singlePage, Map<String, String> formData) {
    final fields = <pw.Widget>[];

    // 添加表单字段（透明边框，用户可直接填写）
    fields.add(_buildTextField('name', 30, 23, 40, 5, formData['name'] ?? '', 9));
    fields.add(_buildTextField('player', 75, 23, 35, 5, formData['player'] ?? '', 9));
    fields.add(_buildTextField('occupation', 115, 23, 50, 5, formData['occupation'] ?? '', 9));
    fields.add(_buildTextField('age', 170, 23, 18, 5, formData['age'] ?? '', 9));
    fields.add(_buildTextField('gender', 190, 23, 15, 5, formData['gender'] ?? '', 9));
    fields.add(_buildTextField('residence', 30, 33, 80, 5, formData['residence'] ?? '', 9));
    fields.add(_buildTextField('birthplace', 115, 33, 50, 5, formData['birthplace'] ?? '', 9));

    // 属性字段
    fields.add(_buildTextField('str', 55, 52, 20, 4, formData['str'] ?? '', 8));
    fields.add(_buildTextField('con', 55, 60, 20, 4, formData['con'] ?? '', 8));
    fields.add(_buildTextField('siz', 55, 68, 20, 4, formData['siz'] ?? '', 8));
    fields.add(_buildTextField('dex', 55, 76, 20, 4, formData['dex'] ?? '', 8));
    fields.add(_buildTextField('app', 55, 84, 20, 4, formData['app'] ?? '', 8));
    fields.add(_buildTextField('int', 55, 92, 20, 4, formData['int'] ?? '', 8));
    fields.add(_buildTextField('pow', 55, 100, 20, 4, formData['pow'] ?? '', 8));
    fields.add(_buildTextField('edu', 55, 108, 20, 4, formData['edu'] ?? '', 8));

    // 衍生属性
    fields.add(_buildTextField('hp', 32, 120, 25, 4, formData['hp'] ?? '', 8));
    fields.add(_buildTextField('mp', 58, 120, 25, 4, formData['mp'] ?? '', 8));
    fields.add(_buildTextField('sanity', 85, 120, 28, 4, formData['sanity'] ?? '', 8));
    fields.add(_buildTextField('luck', 115, 120, 25, 4, formData['luck'] ?? '', 8));
    fields.add(_buildTextField('move', 148, 120, 18, 4, formData['move'] ?? '', 8));
    fields.add(_buildTextField('build', 168, 120, 18, 4, formData['build'] ?? '', 8));
    fields.add(_buildTextField('damageBonus', 188, 120, 18, 4, formData['damageBonus'] ?? '', 8));

    // 技能（只读显示）
    double yMm = 132;
    for (final entry in character.skills.entries) {
      if (fields.length >= 50) break;
      fields.add(pw.Positioned(
        left: mm(30),
        top: mm(yMm),
        child: pw.Text('${entry.key} ${entry.value}%', style: _ts(5.5)),
      ));
      yMm += 3.5;
    }

    return pw.Stack(
      children: [
        if (bg1 != null)
          pw.Positioned.fill(
            child: pw.Image(pw.MemoryImage(bg1), fit: pw.BoxFit.cover),
          ),
        ...fields,
      ],
    );
  }

  static pw.Widget _buildFillablePage2(Character character, Uint8List? bg2, Map<String, String> formData) {
    final fields = <pw.Widget>[];

    // 武器（只读显示）
    double yMm = 30;
    for (final w in character.weapons) {
      if (fields.length >= 10) break;
      fields.add(pw.Positioned(left: mm(30), top: mm(yMm), child: pw.Text(w.name, style: _ts(7))));
      fields.add(pw.Positioned(left: mm(95), top: mm(yMm), child: pw.Text('${w.skill}%', style: _ts(7))));
      fields.add(pw.Positioned(left: mm(125), top: mm(yMm), child: pw.Text(w.damage, style: _ts(7))));
      fields.add(pw.Positioned(left: mm(155), top: mm(yMm), child: pw.Text(w.range, style: _ts(7))));
      yMm += 7;
    }

    // 财务字段
    fields.add(_buildTextField('cash', 40, 113, 45, 5, formData['cash'] ?? '', 9));
    fields.add(_buildTextField('spending', 90, 113, 45, 5, formData['spending'] ?? '', 9));
    fields.add(_buildTextField('assets', 140, 113, 45, 5, formData['assets'] ?? '', 9));

    // 背景故事
    fields.add(_buildTextField('backstory', 30, 128, 150, 40, formData['backstory'] ?? '', 6, multiLine: true));

    return pw.Stack(
      children: [
        if (bg2 != null)
          pw.Positioned.fill(
            child: pw.Image(pw.MemoryImage(bg2), fit: pw.BoxFit.cover),
          ),
        ...fields,
      ],
    );
  }

  static pw.Widget _buildTextField(String fieldName, double left, double top, double width, double height, String value, double fontSize, {bool multiLine = false}) {
    return pw.Positioned(
      left: mm(left),
      top: mm(top),
      child: pw.TextField(
        name: fieldName,
        defaultValue: value,
        width: mm(width),
        height: mm(height),
      ),
    );
  }

  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    try {
      final fontData = await rootBundle.load('assets/Noto_Sans_SC/static/NotoSansSC-Regular.ttf');
      _chineseFont = pw.Font.ttf(fontData);
    } catch (e) {}
    _fontsLoaded = true;
  }

  static Future<Uint8List?> _loadImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  static double mm(double mm) => mm * 2.835;

  static pw.TextStyle _ts(double size) {
    return pw.TextStyle(font: _chineseFont, fontSize: size);
  }

  // ==================== 第一页 ====================
  static pw.Widget _buildPage1(Character character, Uint8List? bg1, bool singlePage) {
    return pw.Stack(
      children: [
        if (bg1 != null)
          pw.Positioned.fill(
            child: pw.Image(pw.MemoryImage(bg1), fit: pw.BoxFit.cover),
          ),
        // 姓名
        pw.Positioned(left: mm(30), top: mm(23), child: pw.Text(character.name, style: _ts(9))),
        // 玩家
        pw.Positioned(left: mm(75), top: mm(23), child: pw.Text(character.player, style: _ts(9))),
        // 职业
        pw.Positioned(left: mm(115), top: mm(23), child: pw.Text(character.occupation, style: _ts(9))),
        // 年龄
        pw.Positioned(left: mm(170), top: mm(23), child: pw.Text(character.age, style: _ts(9))),
        // 性别
        pw.Positioned(left: mm(190), top: mm(23), child: pw.Text(character.gender, style: _ts(9))),
        // 居住地
        pw.Positioned(left: mm(30), top: mm(33), child: pw.Text(character.residence, style: _ts(9))),
        // 出生地
        pw.Positioned(left: mm(115), top: mm(33), child: pw.Text(character.birthplace, style: _ts(9))),
        // 属性值
        pw.Positioned(left: mm(55), top: mm(52), child: pw.Text('${character.str}', style: _ts(8))),
        pw.Positioned(left: mm(55), top: mm(60), child: pw.Text('${character.con}', style: _ts(8))),
        pw.Positioned(left: mm(55), top: mm(68), child: pw.Text('${character.siz}', style: _ts(8))),
        pw.Positioned(left: mm(55), top: mm(76), child: pw.Text('${character.dex}', style: _ts(8))),
        pw.Positioned(left: mm(55), top: mm(84), child: pw.Text('${character.app}', style: _ts(8))),
        pw.Positioned(left: mm(55), top: mm(92), child: pw.Text('${character.int_}', style: _ts(8))),
        pw.Positioned(left: mm(55), top: mm(100), child: pw.Text('${character.pow}', style: _ts(8))),
        pw.Positioned(left: mm(55), top: mm(108), child: pw.Text('${character.edu}', style: _ts(8))),
        // 衍生属性
        pw.Positioned(left: mm(32), top: mm(120), child: pw.Text('${character.currentHp}/${character.maxHp}', style: _ts(8))),
        pw.Positioned(left: mm(58), top: mm(120), child: pw.Text('${character.currentMp}/${character.maxMp}', style: _ts(8))),
        pw.Positioned(left: mm(85), top: mm(120), child: pw.Text('${character.sanity}/${character.maxSanity}', style: _ts(8))),
        pw.Positioned(left: mm(115), top: mm(120), child: pw.Text('${character.luck}', style: _ts(8))),
        pw.Positioned(left: mm(148), top: mm(120), child: pw.Text('${character.move}', style: _ts(8))),
        pw.Positioned(left: mm(168), top: mm(120), child: pw.Text('${character.build}', style: _ts(8))),
        pw.Positioned(left: mm(188), top: mm(120), child: pw.Text(character.damageBonus, style: _ts(8))),
        // 技能
        ..._buildSkillsWidgets(character),
      ],
    );
  }

  static List<pw.Widget> _buildSkillsWidgets(Character character) {
    final widgets = <pw.Widget>[];
    double yMm = 132;
    for (final entry in character.skills.entries) {
      if (widgets.length >= 50) break;
      widgets.add(pw.Positioned(left: mm(30), top: mm(yMm), child: pw.Text('${entry.key} ${entry.value}%', style: _ts(5.5))));
      yMm += 3.5;
    }
    return widgets;
  }

  // ==================== 第二页 ====================
  static pw.Widget _buildPage2(Character character, Uint8List? bg2) {
    return pw.Stack(
      children: [
        if (bg2 != null)
          pw.Positioned.fill(
            child: pw.Image(pw.MemoryImage(bg2), fit: pw.BoxFit.cover),
          ),
        // 武器
        ..._buildWeaponsWidgets(character),
        // 财务
        pw.Positioned(left: mm(40), top: mm(113), child: pw.Text('${character.cash}', style: _ts(9))),
        pw.Positioned(left: mm(90), top: mm(113), child: pw.Text('${character.spending}', style: _ts(9))),
        pw.Positioned(left: mm(140), top: mm(113), child: pw.Text('${character.assets}', style: _ts(9))),
        // 背景故事
        pw.Positioned(
          left: mm(30), top: mm(128),
          child: pw.Container(width: mm(150), child: pw.Text(character.backstory, style: _ts(6))),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildWeaponsWidgets(Character character) {
    final widgets = <pw.Widget>[];
    double yMm = 30;
    for (final w in character.weapons) {
      if (widgets.length >= 10) break;
      widgets.add(pw.Positioned(left: mm(30), top: mm(yMm), child: pw.Text(w.name, style: _ts(7))));
      widgets.add(pw.Positioned(left: mm(95), top: mm(yMm), child: pw.Text('${w.skill}%', style: _ts(7))));
      widgets.add(pw.Positioned(left: mm(125), top: mm(yMm), child: pw.Text(w.damage, style: _ts(7))));
      widgets.add(pw.Positioned(left: mm(155), top: mm(yMm), child: pw.Text(w.range, style: _ts(7))));
      yMm += 7;
    }
    return widgets;
  }
}
