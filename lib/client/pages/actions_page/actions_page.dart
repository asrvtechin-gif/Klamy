import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../notification_page/notification_page.dart';
import '../../components/grievance_draft_sheet.dart';
import 'actions_controller.dart';

class ActionsPage extends StatelessWidget {
  ActionsPage({super.key});

  final ActionsController controller = Get.find<ActionsController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Bar (Action Center + Bell Icon)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'action_center'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                  letterSpacing: -0.3,
                ),
              ),

              // Notification Bell Icon with Dot
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
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildComplaintTrackingSection(context),

          const SizedBox(height: 24),

          // 2. Filter Chips Row
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: '${'urgent'.tr} (${controller.urgentCount})',
                    icon: Icons.error_outline_rounded,
                    categoryKey: 'Urgent',
                    activeBgColor: const Color(0xFFEF4444),
                    activeFgColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '${'upcoming'.tr} (${controller.upcomingCount})',
                    icon: Icons.access_time_rounded,
                    categoryKey: 'Upcoming',
                    activeBgColor: const Color(0xFF0F2942),
                    activeFgColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '${'completed'.tr} (${controller.completedCount})',
                    icon: Icons.check_circle_outline_rounded,
                    categoryKey: 'Completed',
                    activeBgColor: const Color(0xFF10B981),
                    activeFgColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Sections Content List
          Obx(() {
            final filter = controller.selectedFilter.value;

            final urgentList = controller.actionItems
                .where(
                  (item) => item.category == 'Urgent' && !item.isDone.value,
                )
                .toList();
            final upcomingList = controller.actionItems
                .where(
                  (item) => item.category == 'Upcoming' && !item.isDone.value,
                )
                .toList();
            final completedList = controller.actionItems
                .where(
                  (item) => item.isDone.value || item.category == 'Completed',
                )
                .toList();
            final hasVisibleActions = filter == 'Urgent'
                ? urgentList.isNotEmpty
                : filter == 'Upcoming'
                ? upcomingList.isNotEmpty
                : filter == 'Completed'
                ? completedList.isNotEmpty
                : urgentList.isNotEmpty ||
                      upcomingList.isNotEmpty ||
                      completedList.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasVisibleActions) _buildNoActionsState(filter),
                // URGENT SECTION
                if ((filter == 'All' || filter == 'Urgent') &&
                    urgentList.isNotEmpty) ...[
                  const Text(
                    'Urgent',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...urgentList.map((item) => _buildUrgentCard(context, item)),
                  const SizedBox(height: 24),
                ],

                // UPCOMING SECTION
                if ((filter == 'All' || filter == 'Upcoming') &&
                    upcomingList.isNotEmpty) ...[
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...upcomingList.map(
                    (item) => _buildUpcomingCard(context, item),
                  ),
                  const SizedBox(height: 24),
                ],

                // COMPLETED SECTION
                if ((filter == 'All' || filter == 'Completed') &&
                    completedList.isNotEmpty) ...[
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completedList.map(
                    (item) => _buildCompletedCard(context, item),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComplaintTrackingSection(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F7F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: Color(0xFF0F766E),
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'IRDAI claim complaints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Track a complaint',
              onPressed: () => _showTrackComplaintDialog(context),
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: const Color(0xFF0F766E),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'First raise the issue with your insurer. If it is unresolved, file with IRDAI on Bima Bharosa. After filing, save the IRDAI token here to track it in Klamy.',
          style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                if (controller.claims.isEmpty) {
                  Get.snackbar('No Claims', 'Create or select a claim first to draft a complaint letter.');
                  return;
                }
                _showSelectClaimForGrievanceDialog(context);
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('AI Draft & Email GRO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final opened = await controller.openBimaBharosa();
                if (!opened) {
                  Get.snackbar(
                    'Could not open IRDAI',
                    'Try again or open bimabharosa.irdai.gov.in in your browser.',
                  );
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('File on Bima Bharosa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF99D7D1)),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final opened = await controller.openBimaBharosa(
                  registerComplaint: false,
                );
                if (!opened) {
                  Get.snackbar(
                    'Could not open IRDAI',
                    'Try again or open bimabharosa.irdai.gov.in in your browser.',
                  );
                }
              },
              icon: const Icon(Icons.track_changes_rounded, size: 17),
              label: const Text('Check portal status'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Obx(() {
          if (controller.complaints.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No IRDAI complaints are being tracked yet.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            );
          }
          return Column(
            children: controller.complaints
                .map((complaint) => _buildComplaintCard(complaint))
                .toList(),
          );
        }),
      ],
    ),
  );

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final status =
        ActionsController.complaintStatuses.contains(complaint['status'])
        ? complaint['status'].toString()
        : 'New';
    final updatedAt = complaint['updatedAt'];
    final updatedText = updatedAt is num
        ? DateTime.fromMillisecondsSinceEpoch(
            updatedAt.toInt(),
          ).toLocal().toString().substring(0, 16)
        : 'Just now';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (complaint['claimTitle'] ?? 'Health claim').toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Insurer: ${(complaint['insurer'] ?? 'Not specified').toString()} | IRDAI token: ${(complaint['irdaToken'] ?? '').toString()}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Status',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: status,
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: ActionsController.complaintStatuses
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    try {
                      await controller.updateComplaintStatus(
                        complaintId: (complaint['id'] ?? '').toString(),
                        status: value,
                      );
                    } catch (error) {
                      Get.snackbar('Status not saved', error.toString());
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: 'Open Bima Bharosa to verify status',
                onPressed: () async {
                  final opened = await controller.openBimaBharosa(
                    registerComplaint: false,
                  );
                  if (!opened) {
                    Get.snackbar(
                      'Could not open IRDAI',
                      'Try again or open bimabharosa.irdai.gov.in in your browser.',
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                color: const Color(0xFF0F766E),
              ),
            ],
          ),
          Text(
            'Last updated $updatedText. Check the official portal and update this status here.',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  void _showTrackComplaintDialog(BuildContext context) {
    if (controller.claims.isEmpty) {
      Get.snackbar(
        'No claims found',
        'Create a claim in Klamy before adding its IRDAI complaint token.',
      );
      return;
    }
    final tokenController = TextEditingController();
    var selectedClaimId = controller.claims.first['id']?.toString() ?? '';
    var isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Track an IRDAI complaint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File the complaint on the official Bima Bharosa website first. Keep your IRDAI token number, then return here to save it.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedClaimId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Klamy claim',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.claims.map((claim) {
                    final id = claim['id']?.toString() ?? '';
                    final title = (claim['title'] ?? 'Health claim').toString();
                    return DropdownMenuItem(
                      value: id,
                      child: Text(title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedClaimId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final opened = await controller.openBimaBharosa();
                      if (!opened) {
                        Get.snackbar(
                          'Could not open IRDAI',
                          'Try again or open bimabharosa.irdai.gov.in in your browser.',
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('Open official complaint form'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tokenController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'IRDAI token number',
                    hintText: 'Enter the token from IRDAI SMS/email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Use the actual insurer claim number on IRDAI's form. The status shown in Klamy is updated manually from the official portal.",
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final token = tokenController.text.trim();
                      if (selectedClaimId.isEmpty || token.isEmpty) {
                        Get.snackbar(
                          'Missing details',
                          'Select a claim and enter the IRDAI token.',
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        await controller.saveComplaint(
                          claimId: selectedClaimId,
                          irdaToken: token,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        Get.snackbar(
                          'Complaint saved',
                          'The IRDAI complaint is now listed in Actions.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (error) {
                        Get.snackbar(
                          'Could not save complaint',
                          error.toString(),
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save token'),
            ),
          ],
        ),
      ),
    ).whenComplete(tokenController.dispose);
  }

  void _showSelectClaimForGrievanceDialog(BuildContext context) {
    var selectedClaimId = controller.claims.first['id']?.toString() ?? '';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Claim for Grievance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the health claim that has been rejected or delayed to generate a legal grievance letter.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: selectedClaimId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Klamy claim',
                border: OutlineInputBorder(),
              ),
              items: controller.claims.map((claim) {
                final id = claim['id']?.toString() ?? '';
                final title = (claim['title'] ?? 'Health claim').toString();
                final insurer = (claim['insurer'] ?? '').toString();
                return DropdownMenuItem(
                  value: id,
                  child: Text('$title ($insurer)', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) selectedClaimId = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(dialogContext);
              final claim = controller.claims.firstWhere(
                (c) => c['id']?.toString() == selectedClaimId,
                orElse: () => controller.claims.first,
              );
              GrievanceDraftSheet.show(context, claim);
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Draft Letter'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActionsState(String filter) {
    final title = filter == 'All'
        ? 'No actions found'
        : 'No $filter actions found';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE6F7F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 30,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New actions related to your claims will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // Filter Chip Widget
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required String categoryKey,
    required Color activeBgColor,
    required Color activeFgColor,
  }) {
    final bool isSelected = controller.selectedFilter.value == categoryKey;

    return InkWell(
      onTap: () => controller.setFilter(categoryKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeBgColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeFgColor : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? activeFgColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Urgent Card (Red Tinted)
  Widget _buildUrgentCard(BuildContext context, ActionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4E6)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.completeItem(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconFg, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Upcoming Card (White Container with Blue Icon)
  Widget _buildUpcomingCard(BuildContext context, ActionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.completeItem(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconFg, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Completed Card (White/Light Green Container with Solid Green Checkmark)
  Widget _buildCompletedCard(BuildContext context, ActionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.completeItem(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
