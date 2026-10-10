import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'claim_assistant_sheet.dart';
import 'skeleton_box.dart';
import '../pages/claims_page/claims_controller.dart';

class RecentClaimCardWidget extends StatelessWidget {
  final VoidCallback? onViewAll;

  const RecentClaimCardWidget({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ClaimsController>()
        ? Get.find<ClaimsController>()
        : Get.put(ClaimsController());

    return Obx(() {
      final claims = controller.claimsList;
      final latestClaim = claims.isEmpty ? null : claims.first;
      final isLoading = controller.isLoadingClaims.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recent_claim'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      'view_all'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00A3A1),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF00A3A1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            _buildLoadingCard()
          else if (latestClaim == null)
            _buildEmptyState()
          else
            _buildClaimCard(context, latestClaim),
        ],
      );
    });
  }

  Widget _buildLoadingCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SkeletonBox(width: 42, height: 42, radius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 130, height: 13),
                  SizedBox(height: 8),
                  SkeletonBox(width: 185, height: 10),
                ],
              ),
            ),
            SkeletonBox(width: 58, height: 22, radius: 12),
          ],
        ),
        const SizedBox(height: 18),
        const SkeletonBox(height: 8, radius: 5),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: SkeletonBox(height: 32)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 32)),
          ],
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        const Icon(Icons.description_outlined, size: 30, color: Color(0xFF94A3B8)),
        const SizedBox(height: 8),
        Text(
          'no_recent_claims'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F2942),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'submitted_claims_appear'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    ),
  );

  Widget _buildClaimCard(BuildContext context, Map<String, dynamic> claim) {
    final status = (claim['status'] ?? 'Submitted').toString();
    final statusColor = status == 'Approved'
        ? const Color(0xFF0284C7)
        : status == 'Rejected'
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    final progress = ((claim['progress'] as num?)?.toDouble() ?? 0.25).clamp(
      0.0,
      1.0,
    );
    final amount = claim['amount'];
    final amountText = amount is num
        ? '₹${amount.toStringAsFixed(0)}'
        : '₹${amount ?? 0}';
    final createdAt = claim['createdAt'];
    final daysActive = createdAt is num
        ? '${DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(createdAt.toInt())).inDays + 1} days'
        : (claim['daysActive'] ?? '1 day').toString();

    return InkWell(
      onTap: () => ClaimAssistantSheet.show(context, claim),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (claim['title'] ?? 'Health Claim').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Claim No: ${(claim['id'] ?? '').toString()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00A3A1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth < 520
                    ? (constraints.maxWidth - 16) / 2
                    : (constraints.maxWidth - 48) / 4;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatColumn(amountText, 'Claim Amount'),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatColumn(
                        (claim['docsCount'] ?? '0 / 6').toString(),
                        'Documents',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatColumn(daysActive, 'Days active'),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatColumn(
                        (claim['openActions'] ?? 0).toString(),
                        'Open actions',
                        valueColor: const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {Color? valueColor}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      );
}
