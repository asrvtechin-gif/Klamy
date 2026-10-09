import 'package:flutter/material.dart';

class BackgroundHeaderWidget extends StatelessWidget {
  final String? imageUrl;
  final double height;

  const BackgroundHeaderWidget({
    super.key,
    this.imageUrl,
    this.height = 420.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),

          // Smooth Gradient Overlay blending image into dark theme
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x33121212),
                  Color(0xCC121212),
                  Color(0xFF121212),
                ],
                stops: [0.0, 0.45, 0.80, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackGradient();
    }

    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(),
    );
  }

  Widget _buildFallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF333333), Color(0xFF121212)],
        ),
      ),
    );
  }
}
