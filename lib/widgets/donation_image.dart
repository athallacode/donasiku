import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class DonationImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? errorWidget;

  const DonationImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract base64 part
        final String base64Data = imageUrl.split(',').last;
        final Uint8List bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? const Center(child: Icon(Icons.broken_image)),
        );
      } catch (e) {
        return errorWidget ?? const Center(child: Icon(Icons.broken_image));
      }
    }

    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? const Center(child: Icon(Icons.broken_image)),
    );
  }
}
