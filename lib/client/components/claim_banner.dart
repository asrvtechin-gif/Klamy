import 'package:flutter/material.dart';

class ClaimBannerWidget extends StatelessWidget {
  final VoidCallback? onViewDetails;

  const ClaimBannerWidget({
    super.key,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F5),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFC7EFEA), width: 1),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your claim is under review',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(
                width: 210,
                child: Text(
                  "We'll notify you as soon as there's an update.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5B7083),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: onViewDetails,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB0E5E0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View claim details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00A3A1),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF00A3A1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Illustration Badge Graphics on Right
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: Center(
              child: Container(
                width: 76,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A3A1).withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD0EBEB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 24,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD0EBEB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A3A1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A3A1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
