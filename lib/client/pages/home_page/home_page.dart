import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../components/claim_banner.dart';
import '../../components/metric_card.dart';
import '../../components/quick_action_card.dart';
import '../../components/recent_claim_card.dart';
import '../actions_page/actions_page.dart';
import '../claims_page/claims_controller.dart';
import '../claims_page/claims_page.dart';
import '../documents_page/documents_page.dart';
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

        // 1. If on Claims page stepper (step 2, 3, or 4), go back to previous step
        if (controller.selectedNavIndex.value == 2 &&
            Get.isRegistered<ClaimsController>()) {
          final claimsController = Get.find<ClaimsController>();
          if (claimsController.currentStep.value > 1) {
            claimsController.prevStep();
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

            // Bottom Navigation Bar (Hidden when on Claims Page / Index 2)
            bottomNavigationBar: Obx(() {
              final bool isClaimsPage = controller.selectedNavIndex.value == 2;
              if (isClaimsPage) {
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
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.article_outlined),
                      label: 'Documents',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.verified_outlined),
                      label: 'Claims',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add_circle_outline_rounded),
                      label: 'Actions',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      label: 'Profile',
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
              Stack(
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
                  Positioned(
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Home Dashboard View
  Widget _buildHomeView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header
          Obx(() => Text(
                'Good morning,\n${controller.userName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                  height: 1.2,
                ),
              )),
          const SizedBox(height: 6),
          const Text(
            'Your health claims, simplified.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 20),

          // Claim Review Banner
          ClaimBannerWidget(
            onViewDetails: () {
              controller.changeNavIndex(2); // Jump to Claims tab
            },
          ),

          const SizedBox(height: 20),

          // Metric Cards Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => controller.changeNavIndex(1),
                  child: const MetricCardWidget(
                    icon: Icons.description_outlined,
                    iconBgColor: Color(0xFFE0F2FE),
                    iconColor: Color(0xFF0284C7),
                    title: 'Documents',
                    subtitle: '3 pending',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => controller.changeNavIndex(3),
                  child: const MetricCardWidget(
                    icon: Icons.verified_user_outlined,
                    iconBgColor: Color(0xFFDCFCE7),
                    iconColor: Color(0xFF16A34A),
                    title: 'Readiness',
                    subtitle: '82% complete',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => controller.changeNavIndex(2),
                  child: const MetricCardWidget(
                    icon: Icons.access_time_rounded,
                    iconBgColor: Color(0xFFF3E8FF),
                    iconColor: Color(0xFF9333EA),
                    title: 'Timeline',
                    subtitle: 'Next: 12 Sep',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => controller.changeNavIndex(1),
                  child: const MetricCardWidget(
                    icon: Icons.note_alt_outlined,
                    iconBgColor: Color(0xFFFFEDD5),
                    iconColor: Color(0xFFEA580C),
                    title: 'Evidence Pack',
                    subtitle: 'Ready to generate',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Claim Section
          RecentClaimCardWidget(
            onViewAll: () => controller.changeNavIndex(2),
          ),

          const SizedBox(height: 24),

          // Quick Actions Section
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickActionCardWidget(
                  icon: Icons.note_add_outlined,
                  iconBgColor: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Upload Documents',
                  subtitle: 'Add bills, reports, prescriptions',
                  onTap: () => controller.changeNavIndex(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionCardWidget(
                  icon: Icons.search_rounded,
                  iconBgColor: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF9333EA),
                  title: 'Check Claim Readiness',
                  subtitle: 'Find missing documents & more',
                  onTap: () => controller.changeNavIndex(3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
