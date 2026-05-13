import 'package:flutter/material.dart';

/// Ảnh tròn dùng chung cho avatar (URL HTTP/HTTPS hoặc asset),
/// có sẵn fallback và `cacheWidth`/`cacheHeight` để giảm RAM khi decode.
///
/// - Khi [source] trống hoặc lỗi load → render [fallbackAsset].
/// - `cacheWidth`/`cacheHeight` được tính theo kích thước hiển thị thực
///   (logicalSize × devicePixelRatio) để Flutter không decode ảnh ở
///   resolution gốc (vd 4000×4000) khi UI chỉ vẽ 80×80 logical px.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.source,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/logo/friend_logo.png',
  });

  final String source;
  final double width;
  final double height;
  final BoxFit fit;
  final String fallbackAsset;

  bool get _isNetwork =>
      source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final cacheW = (width * dpr).round();
    final cacheH = (height * dpr).round();

    if (source.isEmpty) {
      return _assetFallback(cacheW, cacheH);
    }

    if (_isNetwork) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        errorBuilder: (_, __, ___) => _assetFallback(cacheW, cacheH),
      );
    }

    return Image.asset(
      source,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      errorBuilder: (_, __, ___) => _assetFallback(cacheW, cacheH),
    );
  }

  Widget _assetFallback(int cacheW, int cacheH) {
    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
    );
  }
}
