import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/claim_repository.dart';

class ActionItem {
  final String id;
  final String claimId;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String? dueDate;
  final String? completedDate;
  final RxBool isDone;

  ActionItem({
    required this.id,
    this.claimId = '',
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    this.dueDate,
    this.completedDate,
    bool done = false,
  }) : isDone = done.obs;
}

class ActionsController extends GetxController {
  static const complaintStatuses = <String>[
    'New',
    'Acknowledged',
    'Pending',
    'Attended To',
    'Escalated',
    'Reopened',
    'Closed',
  ];
  static final bimaBharosaRegistrationUri = Uri.parse(
    'https://bimabharosa.irdai.gov.in/RegComplaint/RegisterComplaint',
  );

  final RxString selectedFilter = 'All'.obs;
  final RxList<ActionItem> actionItems = <ActionItem>[].obs;
  final RxList<Map<String, dynamic>> claims = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> complaints = <Map<String, dynamic>>[].obs;
  late final ClaimRepository _repository;
  StreamSubscription<List<Map<String, dynamic>>>? _actionsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _claimsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _complaintsSubscription;

  @override
  void onInit() {
    super.onInit();
    _repository = Get.isRegistered<ClaimRepository>()
        ? Get.find<ClaimRepository>()
        : Get.put(ClaimRepository(), permanent: true);
    _actionsSubscription = _repository.watchActions().listen(
      (records) => actionItems.assignAll(records.map(_toActionItem)),
      onError: (Object error) => Get.snackbar(
        'Actions unavailable',
        'Could not load your actions: $error',
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
    _claimsSubscription = _repository.watchClaims().listen(
      claims.assignAll,
      onError: (Object error) => Get.snackbar(
        'Claims unavailable',
        'Could not load claims for complaint tracking: $error',
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
    _complaintsSubscription = _repository.watchClaimComplaints().listen(
      complaints.assignAll,
      onError: (Object error) => Get.snackbar(
        'Complaint status unavailable',
        'Could not load your tracked complaints: $error',
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  Future<bool> openBimaBharosa({bool registerComplaint = true}) => launchUrl(
    registerComplaint
        ? bimaBharosaRegistrationUri
        : Uri.parse('https://bimabharosa.irdai.gov.in/'),
    mode: LaunchMode.externalApplication,
  );

  Future<void> saveComplaint({
    required String claimId,
    required String irdaToken,
  }) async {
    final claim = claims.firstWhere(
      (item) => item['id']?.toString() == claimId,
      orElse: () => <String, dynamic>{},
    );
    if (claim.isEmpty) throw StateError('Select a claim to track.');
    await _repository.saveClaimComplaint(
      claimId: claimId,
      claimTitle: (claim['title'] ?? 'Health claim').toString(),
      insurer: (claim['insurer'] ?? '').toString(),
      irdaToken: irdaToken.trim(),
    );
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
  }) => _repository.updateClaimComplaintStatus(
    complaintId: complaintId,
    status: status,
  );

  ActionItem _toActionItem(Map<String, dynamic> record) {
    final done = record['done'] == true;
    final category = done
        ? 'Completed'
        : (record['category'] ?? 'Upcoming').toString();
    final urgent = category == 'Urgent';
    return ActionItem(
      id: (record['id'] ?? '').toString(),
      claimId: (record['claimId'] ?? '').toString(),
      title: (record['title'] ?? 'Review claim').toString(),
      subtitle: (record['subtitle'] ?? '').toString(),
      category: category,
      icon: done
          ? Icons.check_rounded
          : (urgent ? Icons.priority_high_rounded : Icons.description_outlined),
      iconBg: done
          ? const Color(0xFF10B981)
          : (urgent ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
      iconFg: done
          ? Colors.white
          : (urgent ? const Color(0xFFEF4444) : const Color(0xFF0284C7)),
      dueDate: record['dueDate']?.toString(),
      completedDate: record['completedAt']?.toString(),
      done: done,
    );
  }

  int get urgentCount => actionItems
      .where((item) => item.category == 'Urgent' && !item.isDone.value)
      .length;

  int get upcomingCount => actionItems
      .where((item) => item.category == 'Upcoming' && !item.isDone.value)
      .length;

  int get completedCount => actionItems
      .where((item) => item.isDone.value || item.category == 'Completed')
      .length;

  int get pendingCount =>
      actionItems.where((item) => !item.isDone.value).length;

  void setFilter(String filter) {
    selectedFilter.value = selectedFilter.value == filter ? 'All' : filter;
  }

  Future<void> completeItem(ActionItem item) async {
    final wasDone = item.isDone.value;
    final nowDone = !wasDone;
    item.isDone.value = nowDone;
    actionItems.refresh();
    try {
      await _repository.setActionDone(
        actionId: item.id,
        claimId: item.claimId,
        done: nowDone,
      );
      Get.snackbar(
        'Action Updated',
        nowDone
            ? '"${item.title}" marked as completed.'
            : 'Moved back to pending.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F766E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } catch (error) {
      item.isDone.value = wasDone;
      actionItems.refresh();
      Get.snackbar('Could not update action', error.toString());
    }
  }

  @override
  void onClose() {
    _actionsSubscription?.cancel();
    _claimsSubscription?.cancel();
    _complaintsSubscription?.cancel();
    super.onClose();
  }
}
