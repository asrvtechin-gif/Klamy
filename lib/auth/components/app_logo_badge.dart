import 'package:flutter/material.dart';

class AppLogoBadge extends StatelessWidget {
  final String logoPath;
  final double size;

  const AppLogoBadge({
    super.key,
    this.logoPath = 'assets/logo/logo.png',
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6.0),
      child: ClipOval(
        child: Image.asset(
          logoPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
              size: 40,
            );
          },
        ),
      ),
    );
  }
}
