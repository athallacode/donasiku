import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DonationImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? errorWidget;

  /// Ukuran cache di memory (pixels). Otomatis resize agar hemat RAM.
  /// Null = pakai ukuran asli (hanya untuk detail screen).
  final int? cacheWidth;
  final int? cacheHeight;

  const DonationImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Gambar base64 (data:image/...) — tetap pakai Image.memory
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64Data = imageUrl.split(',').last;
        final Uint8List bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) =>
              _defaultError(),
        );
      } catch (e) {
        return _defaultError();
      }
    }

    // URL kosong
    if (imageUrl.isEmpty) return _defaultError();

    // Gambar dari Firebase Storage — pakai CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,

      // Shimmer loading saat gambar masih diunduh
      placeholder: (context, url) => _ShimmerPlaceholder(
        height: height,
        width: width,
      ),

      // Error state
      errorWidget: (context, url, error) => errorWidget ?? _defaultError(),
    );
  }

  Widget _defaultError() {
    return errorWidget ??
        SizedBox(
          height: height,
          width: width,
          child: const Center(child: Icon(Icons.broken_image)),
        );
  }
}

/// Animasi shimmer sederhana sebagai placeholder saat gambar loading
class _ShimmerPlaceholder extends StatefulWidget {
  final double? height;
  final double? width;

  const _ShimmerPlaceholder({this.height, this.width});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade300,
              Colors.grey.shade200,
            ],
          ),
        ),
      ),
    );
  }
}
