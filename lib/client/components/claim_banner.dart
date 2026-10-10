import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/actions_page/actions_controller.dart';
import '../pages/claims_page/claims_controller.dart';

class ClaimBannerWidget extends StatelessWidget {
  final VoidCallback? onViewDetails;
  final VoidCallback? onViewActions;

  const ClaimBannerWidget({super.key, this.onViewDetails, this.onViewActions});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Box 1: Active Claims Count
        Expanded(
          child: Obx(() {
            final claimsController = Get.isRegistered<ClaimsController>()
                ? Get.find<ClaimsController>()
                : Get.put(ClaimsController());
            final int activeCount = claimsController.claimsList.length;

            return _buildCountCard(
              title: 'total_claims'.tr,
              count: '$activeCount',
              countLabel: 'saved_claims'.tr,
              bgColor: const Color(0xFFE6F7F5),
              borderColor: const Color(0xFFC7EFEA),
              badgeColor: const Color(0xFF00A3A1),
              titleColor: const Color(0xFF0F766E),
              btnTextColor: const Color(0xFF00A3A1),
              btnBorderColor: const Color(0xFFB0E5E0),
              icon: Icons.verified_outlined,
              btnText: 'details'.tr,
              onTap: onViewDetails,
            );
          }),
        ),

        const SizedBox(width: 12),

        // Box 2: Pending Actions Count
        Expanded(
          child: Obx(() {
            final actionsController = Get.isRegistered<ActionsController>()
                ? Get.find<ActionsController>()
                : Get.put(ActionsController());
            final int pendingCount = actionsController.pendingCount;

            return _buildCountCard(
              title: 'pending_actions'.tr,
              count: '$pendingCount',
              countLabel: 'pending_actions'.tr,
              bgColor: const Color(0xFFFFF1F2),
              borderColor: const Color(0xFFFFE4E6),
              badgeColor: const Color(0xFFEF4444),
              titleColor: const Color(0xFFEF4444),
              btnTextColor: const Color(0xFFEF4444),
              btnBorderColor: const Color(0xFFFEE2E2),
              icon: Icons.priority_high_rounded,
              btnText: 'actions'.tr,
              onTap: onViewActions,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCountCard({
    required String title,
    required String count,
    required String countLabel,
    required Color bgColor,
    required Color borderColor,
    required Color badgeColor,
    required Color titleColor,
    required Color btnTextColor,
    required Color btnBorderColor,
    required IconData icon,
    required String btnText,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Count Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B7083),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Button
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: btnBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    btnText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: btnTextColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: btnTextColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
