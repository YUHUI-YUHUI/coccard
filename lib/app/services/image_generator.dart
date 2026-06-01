import 'dart:convert';
import 'package:http/http.dart' as http;

/// 图像生成 provider。新增 provider 时只需在此添加枚举并注册到 [ImageGeneratorFactory]。
enum ImageGenProvider {
  stub('未配置'),
  siliconflow('SiliconFlow'),
  zhipu('智谱 CogView');

  final String label;
  const ImageGenProvider(this.label);

  static ImageGenProvider fromKey(String? key) {
    if (key == null) return ImageGenProvider.stub;
    return ImageGenProvider.values.firstWhere(
      (p) => p.name == key,
      orElse: () => ImageGenProvider.stub,
    );
  }
}

/// 一次图像生成的结果。
/// - [url] 远程地址（部分服务返回临时 URL，使用方应尽快下载到本地）。
/// - [bytes] 如果服务直接返回 base64 编码，则提供解码后的字节，url 为空。
class ImageGenResult {
  final String url;
  final List<int>? bytes;
  const ImageGenResult({this.url = '', this.bytes});
}

class ImageGenerationException implements Exception {
  final String message;
  ImageGenerationException(this.message);
  @override
  String toString() => 'ImageGenerationException: $message';
}

/// 图像生成抽象。具体 provider 实现此接口。
abstract class ImageGenerator {
  ImageGenProvider get provider;
  String get defaultModel;

  /// 生成一张图。
  /// [prompt] 描述；[size] 形如 "1024x1024"；[model] 覆盖默认模型。
  Future<ImageGenResult> generate(
    String prompt, {
    String? size,
    String? model,
  });
}

class ImageGeneratorFactory {
  static ImageGenerator create({
    required ImageGenProvider provider,
    required String apiKey,
    String? model,
    http.Client? client,
  }) {
    switch (provider) {
      case ImageGenProvider.siliconflow:
        return SiliconFlowImageGenerator(apiKey: apiKey, model: model, client: client);
      case ImageGenProvider.zhipu:
        return ZhipuImageGenerator(apiKey: apiKey, model: model, client: client);
      case ImageGenProvider.stub:
        return const StubImageGenerator();
    }
  }
}

/// 占位实现：未配置 provider 时返回友好错误。
class StubImageGenerator implements ImageGenerator {
  const StubImageGenerator();

  @override
  ImageGenProvider get provider => ImageGenProvider.stub;

  @override
  String get defaultModel => '';

  @override
  Future<ImageGenResult> generate(String prompt, {String? size, String? model}) async {
    throw ImageGenerationException('未配置图像生成服务，请到设置页选择 provider 并填写 API key');
  }
}

/// SiliconFlow（兼容 OpenAI /v1/images/generations）。
/// 国内访问稳定，常用模型：
/// - black-forest-labs/FLUX.1-schnell（快，免费额度）
/// - black-forest-labs/FLUX.1-dev
/// - stabilityai/stable-diffusion-3-5-large
class SiliconFlowImageGenerator implements ImageGenerator {
  final String apiKey;
  final String? _model;
  final http.Client? _client;
  static const String _endpoint = 'https://api.siliconflow.cn/v1/images/generations';

  SiliconFlowImageGenerator({required this.apiKey, String? model, http.Client? client})
      : _model = model,
        _client = client;

  @override
  ImageGenProvider get provider => ImageGenProvider.siliconflow;

  @override
  String get defaultModel => 'black-forest-labs/FLUX.1-schnell';

  @override
  Future<ImageGenResult> generate(String prompt, {String? size, String? model}) async {
    if (apiKey.trim().isEmpty) {
      throw ImageGenerationException('SiliconFlow API key 未配置');
    }
    final body = {
      'model': model ?? _model ?? defaultModel,
      'prompt': prompt,
      'image_size': size ?? '1024x1024',
      'batch_size': 1,
      'num_inference_steps': 20,
      'guidance_scale': 7.5,
    };
    final client = _client ?? http.Client();
    try {
      final resp = await client.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (resp.statusCode != 200) {
        throw ImageGenerationException('SiliconFlow ${resp.statusCode}: ${resp.body}');
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      // 兼容多种返回结构
      final data = (json['data'] ?? json['images']) as List?;
      if (data == null || data.isEmpty) {
        throw ImageGenerationException('SiliconFlow 返回空结果: ${resp.body}');
      }
      final first = data.first as Map<String, dynamic>;
      final url = (first['url'] ?? first['image_url'] ?? '') as String;
      final b64 = first['b64_json'] as String?;
      if (url.isNotEmpty) return ImageGenResult(url: url);
      if (b64 != null && b64.isNotEmpty) {
        return ImageGenResult(bytes: base64Decode(b64));
      }
      throw ImageGenerationException('SiliconFlow 未返回可用图像数据');
    } finally {
      if (_client == null) client.close();
    }
  }
}

/// 智谱 CogView-4（https://open.bigmodel.cn/api/paas/v4/images/generations）。
class ZhipuImageGenerator implements ImageGenerator {
  final String apiKey;
  final String? _model;
  final http.Client? _client;
  static const String _endpoint = 'https://open.bigmodel.cn/api/paas/v4/images/generations';

  ZhipuImageGenerator({required this.apiKey, String? model, http.Client? client})
      : _model = model,
        _client = client;

  @override
  ImageGenProvider get provider => ImageGenProvider.zhipu;

  @override
  String get defaultModel => 'cogview-4';

  @override
  Future<ImageGenResult> generate(String prompt, {String? size, String? model}) async {
    if (apiKey.trim().isEmpty) {
      throw ImageGenerationException('智谱 API key 未配置');
    }
    final body = {
      'model': model ?? _model ?? defaultModel,
      'prompt': prompt,
      'size': size ?? '1024x1024',
    };
    final client = _client ?? http.Client();
    try {
      final resp = await client.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (resp.statusCode != 200) {
        throw ImageGenerationException('智谱 ${resp.statusCode}: ${resp.body}');
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final data = json['data'] as List?;
      if (data == null || data.isEmpty) {
        throw ImageGenerationException('智谱返回空结果: ${resp.body}');
      }
      final url = (data.first as Map<String, dynamic>)['url'] as String? ?? '';
      if (url.isEmpty) {
        throw ImageGenerationException('智谱未返回 URL');
      }
      return ImageGenResult(url: url);
    } finally {
      if (_client == null) client.close();
    }
  }
}
