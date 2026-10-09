import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String text;

  const CustomGoogleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Sign in with Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.0,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA8C7FA),
          foregroundColor: const Color(0xFF001D35),
          disabledBackgroundColor: const Color(0xFFA8C7FA).withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF001D35)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/google.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF001D35),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
