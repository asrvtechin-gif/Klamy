import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../components/claim_banner.dart';
import '../../components/recent_claim_card.dart';
import '../actions_page/actions_page.dart';
import '../claims_page/claims_controller.dart';
import '../claims_page/claims_page.dart';
import '../documents_page/documents_page.dart';
import '../notification_page/notification_controller.dart';
import '../notification_page/notification_page.dart';
import '../profile_page/profile_page.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If on Claims page (Tab 1 or step > 1), navigate back within Claims page
        if (controller.selectedNavIndex.value == 2 &&
            Get.isRegistered<ClaimsController>()) {
          final claimsController = Get.find<ClaimsController>();
          if (claimsController.selectedTab.value == 1 &&
              claimsController.currentStep.value > 1) {
            claimsController.prevStep();
            return;
          } else if (claimsController.selectedTab.value == 1) {
            claimsController.selectedTab.value = 0;
            return;
          }
        }

        // 2. If on non-Home tab (Documents, Claims, Actions, Profile), return to Home tab (index 0)
        if (controller.selectedNavIndex.value != 0) {
          controller.changeNavIndex(0);
          return;
        }

        // 3. If ALREADY on Home tab, require double back press to exit app
        final DateTime now = DateTime.now();
        if (controller.lastBackPressed == null ||
            now.difference(controller.lastBackPressed!) >
                const Duration(seconds: 2)) {
          controller.lastBackPressed = now;
          Get.snackbar(
            'Press back again to exit',
            'Tap back button once more to close the app',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.white,
            colorText: const Color(0xFF0F2942),
            margin: const EdgeInsets.all(16),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Obx(() {
          final bool isHomeTab = controller.selectedNavIndex.value == 0;

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),

            appBar: isHomeTab ? _buildHomeAppBar(context) : null,

            body: SafeArea(
              top: !isHomeTab,
              child: IndexedStack(
                index: controller.selectedNavIndex.value,
                children: [
                  _buildHomeView(context),
                  DocumentsPage(),
                  ClaimsPage(),
                  ActionsPage(),
                  ProfilePage(),
                ],
              ),
            ),

            // Bottom Navigation Bar
            bottomNavigationBar: Obx(() {
              final bool isClaimsPage = controller.selectedNavIndex.value == 2;
              final bool isCreateClaim =
                  isClaimsPage &&
                  Get.isRegistered<ClaimsController>() &&
                  Get.find<ClaimsController>().selectedTab.value == 1;

              if (isCreateClaim) {
                return const SizedBox.shrink();
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: controller.selectedNavIndex.value,
                  onTap: controller.changeNavIndex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: const Color(0xFF00A3A1),
                  unselectedItemColor: const Color(0xFF64748B),
                  selectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      label: 'home'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.article_outlined),
                      label: 'documents'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.verified_outlined),
                      label: 'claims'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: 'actions'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline_rounded),
                      label: 'profile'.tr,
                    ),
                  ],
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // Official Home AppBar
  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          color: const Color(0xFFF8FAFC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/logo/logo.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.favorite,
                      color: Color(0xFF00A3A1),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Klamy',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Get.to(() => NotificationPage()),
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: Color(0xFF0F2942),
                      ),
                    ),
                    Obx(() {
                      final notifController =
                          Get.find<NotificationController>();
                      if (notifController.unreadCount > 0) {
                        return Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00A3A1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Home Dashboard View
  Widget _buildHomeView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final horizontalPadding = isWide ? 32.0 : 20.0;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      '${controller.greeting}, ${controller.userName}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2942),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'home_tagline'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active Claims & Pending Actions Summary Boxes
                  ClaimBannerWidget(
                    onViewDetails: () => controller.changeNavIndex(2),
                    onViewActions: () => controller.changeNavIndex(3),
                  ),

                  const SizedBox(height: 24),

                  // Recent Claim Section
                  RecentClaimCardWidget(
                    onViewAll: () => controller.changeNavIndex(2),
                  ),

                  const SizedBox(height: 24),

                  // Prominent "Create a Claim" Button (At the bottom of Recent Claim)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.changeNavIndex(2);
                        if (Get.isRegistered<ClaimsController>()) {
                          Get.find<ClaimsController>().switchTab(1);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        'create_claim'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
