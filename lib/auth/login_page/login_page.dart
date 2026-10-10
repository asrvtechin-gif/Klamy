import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../components/app_logo_badge.dart';
import '../components/background_header_widget.dart';
import '../components/carousel_indicator.dart';
import '../components/custom_google_button.dart';
import '../controller/login_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Obx(() {
          final bool isFirstPage = controller.currentPage.value == 0;

          return Stack(
            children: [
              PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.slides.length,
                itemBuilder: (context, index) {
                  final slide = controller.slides[index];
                  final bool isHomePage = index == 0;

                  return Column(
                    children: [
                      BackgroundHeaderWidget(
                        imageUrl: slide.imageUrl,
                        height: screenHeight * 0.58,
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isHomePage) ...[
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slide.subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFFB0B0B0),
                                    height: 1.4,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  slide.subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.4,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 110),
                    ],
                  );
                },
              ),

              Positioned(
                top: screenHeight * 0.50,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isFirstPage ? 1.0 : 0.0,
                    child: const AppLogoBadge(
                      logoPath: 'assets/logo/logo.png',
                      size: 80,
                    ),
                  ),
                ),
              ),

              // Fixed Bottom Controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Carousel Indicator Dots
                      CarouselIndicator(
                        count: controller.slides.length,
                        currentIndex: controller.currentPage.value,
                      ),

                      const SizedBox(height: 28),

                      // Bottom Action Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: CustomGoogleButton(
                          isLoading: controller.isLoading.value,
                          onPressed: controller.signInWithGoogle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
