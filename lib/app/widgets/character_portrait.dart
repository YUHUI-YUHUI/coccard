import 'dart:io';

import 'package:flutter/material.dart';

import '../data/character.dart';

/// 可复用的 PC 形象展示；支持本地头像、远程头像和无图占位状态。
class CharacterPortrait extends StatelessWidget {
  final Character character;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  const CharacterPortrait({
    super.key,
    required this.character,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
  });

  ImageProvider? _imageProvider() {
    final localPath = character.avatarLocalPath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) return FileImage(file);
    }
    final url = character.avatarUrl;
    if (url != null && url.startsWith('http')) return NetworkImage(url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider();
    final colors = Theme.of(context).colorScheme;
    final isCompact =
        (width != null && width! < 96) || (height != null && height! < 96);
    return Semantics(
      image: true,
      label: '${character.name.isEmpty ? '未命名 PC' : character.name}的形象',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colors.outlineVariant),
          image: image == null ? null : DecorationImage(image: image, fit: fit),
        ),
        alignment: Alignment.center,
        child: image == null
            ? isCompact
                ? Icon(Icons.person_outline,
                    size: 24, color: colors.onSurfaceVariant)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline,
                          size: 42, color: colors.onSurfaceVariant),
                      const SizedBox(height: 6),
                      Text(
                        '添加 PC 形象',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  )
            : null,
      ),
    );
  }
}
