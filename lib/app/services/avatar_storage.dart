import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 头像文件存储：把图片字节/远程 URL 落地到 app docs/avatars 目录，并返回本地路径。
class AvatarStorage {
  AvatarStorage._();

  static Future<Directory> _avatarDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/avatars');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 把给定字节保存到 avatars 目录，返回本地绝对路径。
  static Future<String> saveBytes({
    required int characterId,
    required List<int> bytes,
    String ext = 'png',
  }) async {
    final dir = await _avatarDir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${characterId}_$ts.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// 下载远程 URL 并保存到本地，返回本地路径。
  static Future<String> downloadAndSave({
    required int characterId,
    required String url,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final resp = await c.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        throw Exception('下载失败 ${resp.statusCode}');
      }
      // 简单根据 Content-Type 推扩展名
      final contentType = resp.headers['content-type'] ?? '';
      String ext = 'png';
      if (contentType.contains('jpeg') || contentType.contains('jpg')) ext = 'jpg';
      if (contentType.contains('webp')) ext = 'webp';
      return await saveBytes(characterId: characterId, bytes: resp.bodyBytes, ext: ext);
    } finally {
      if (client == null) c.close();
    }
  }

  /// 复制相册/相机选出的本地文件到 avatars 目录（避免原文件被清理/删除）。
  static Future<String> importFile({
    required int characterId,
    required String sourcePath,
  }) async {
    final src = File(sourcePath);
    final bytes = await src.readAsBytes();
    final ext = sourcePath.split('.').last.toLowerCase();
    final safeExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp') ? ext : 'png';
    return saveBytes(characterId: characterId, bytes: bytes, ext: safeExt);
  }

  /// 删除一个旧头像文件（容错：不存在时静默忽略）。
  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // ignore
    }
  }
}
