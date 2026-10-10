import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/claim_document_upload_service.dart';
import '../../../services/claim_repository.dart';
import '../home_page/home_controller.dart';

class ClaimsController extends GetxController {
  final RxInt selectedTab = 0.obs;
  final RxInt currentStep = 1.obs;
  final RxBool isUploadingDocuments = false.obs;
  final RxBool isSubmittingClaim = false.obs;
  final RxBool isLoadingClaims = true.obs;
  final RxString selectedDocumentCategory = 'policy'.obs;
  final RxList<ClaimDocumentUpload> uploadedDocuments =
      <ClaimDocumentUpload>[].obs;
  final RxList<Map<String, dynamic>> claimsList = <Map<String, dynamic>>[].obs;

  final RxString selectedInsurer = ''.obs;
  final TextEditingController policyNumberController = TextEditingController();
  final TextEditingController policyHolderController = TextEditingController();
  final RxString startDate = ''.obs;
  final RxString endDate = ''.obs;

  final TextEditingController claimTitleController = TextEditingController();
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController hospitalNameController = TextEditingController();
  final TextEditingController claimAmountController = TextEditingController();
  final RxString admissionDate = ''.obs;

  late final ClaimRepository _repository;
  StreamSubscription<List<Map<String, dynamic>>>? _claimsSubscription;

  final List<String> insurers = const [
    'Star Health Insurance',
    'HDFC ERGO Health',
    'ICICI Lombard',
    'Care Health Insurance',
    'Niva Bupa Health Insurance',
    'Aditya Birla Health Insurance',
  ];

  @override
  void onInit() {
    super.onInit();
    _repository = Get.isRegistered<ClaimRepository>()
        ? Get.find<ClaimRepository>()
        : Get.put(ClaimRepository(), permanent: true);
    _claimsSubscription = _repository.watchClaims().listen(
      (claims) {
        claimsList.assignAll(claims);
        isLoadingClaims.value = false;
      },
      onError: (Object error) {
        isLoadingClaims.value = false;
        _showError('Could not load claims: $error');
      },
    );
  }

  void switchTab(int index) {
    selectedTab.value = index;
    if (index == 1 && currentStep.value == 0) currentStep.value = 1;
  }

  void setInsurer(String? value) {
    if (value != null) selectedInsurer.value = value;
  }

  void nextStep() {
    if (isUploadingDocuments.value || isSubmittingClaim.value) return;
    if (!_validateStep(currentStep.value)) return;
    if (currentStep.value < 4) {
      currentStep.value++;
    } else {
      submitNewClaim();
    }
  }

  bool _validateStep(int step) {
    if (step == 1) {
      if (selectedInsurer.value.isEmpty ||
          policyNumberController.text.trim().isEmpty ||
          policyHolderController.text.trim().isEmpty ||
          startDate.value.isEmpty ||
          endDate.value.isEmpty) {
        _showError('Complete all policy details before continuing.');
        return false;
      }
      final start = _parseDate(startDate.value)!;
      final end = _parseDate(endDate.value)!;
      if (!end.isAfter(start)) {
        _showError('Policy end date must be after its start date.');
        return false;
      }
    }
    if (step == 2) {
      final amount = double.tryParse(
        claimAmountController.text.replaceAll(',', '').trim(),
      );
      if (claimTitleController.text.trim().isEmpty ||
          patientNameController.text.trim().isEmpty ||
          hospitalNameController.text.trim().isEmpty ||
          amount == null ||
          amount <= 0 ||
          admissionDate.value.isEmpty) {
        _showError('Complete all claim details and enter a valid amount.');
        return false;
      }
      if (!_admissionDateFitsPolicy()) {
        _showError(
          'Admission date must fall within the policy validity dates.',
        );
        return false;
      }
    }
    if (step == 3 &&
        !uploadedDocuments.any((doc) => doc.category == 'policy')) {
      _showError('Upload the required policy document before continuing.');
      return false;
    }
    return true;
  }

  bool _admissionDateFitsPolicy() {
    final admission = _parseDate(admissionDate.value);
    final start = _parseDate(startDate.value);
    final end = _parseDate(endDate.value);
    if (admission == null || start == null || end == null) return false;
    final day = DateTime(admission.year, admission.month, admission.day);
    final firstDay = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);
    return !day.isBefore(firstDay) && !day.isAfter(lastDay);
  }

  Future<void> pickAndUploadDocuments() async {
    if (isUploadingDocuments.value) return;
    if (!ClaimDocumentUploadService.isConfigured) {
      _showUploadError(
        'Cloudinary setup is missing. Configure CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET, then restart the app.',
      );
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      isUploadingDocuments.value = true;
      final uploadService = Get.put(
        ClaimDocumentUploadService(),
        permanent: false,
      );
      var uploadedCount = 0;
      final failures = <String>[];
      for (final file in result.files) {
        if (file.size > 10 * 1024 * 1024) {
          failures.add('${file.name} (10 MB limit)');
          continue;
        }
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          failures.add('${file.name} (file read failed)');
          continue;
        }
        try {
          final uploaded = await uploadService.upload(
            fileName: file.name,
            bytes: bytes,
            category: selectedDocumentCategory.value,
          );
          final recordId = await _repository.saveUploadedDocument(
            uploaded.toJson(),
          );
          uploadedDocuments.add(uploaded.withRecordId(recordId));
          uploadedCount++;
        } catch (error) {
          failures.add('${file.name}: $error');
        }
      }
      if (uploadedCount > 0) {
        Get.snackbar(
          'Documents uploaded',
          '$uploadedCount file(s) uploaded to Cloudinary.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F766E),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
      if (failures.isNotEmpty) {
        _showUploadError(
          'Some files were not uploaded: ${failures.join(', ')}',
        );
      }
    } catch (error) {
      _showUploadError('$error');
    } finally {
      isUploadingDocuments.value = false;
    }
  }

  Future<void> submitNewClaim() async {
    if (isSubmittingClaim.value || !_validateAllSteps()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Please sign in before submitting a claim.');
      return;
    }

    isSubmittingClaim.value = true;
    final amount = double.parse(
      claimAmountController.text.replaceAll(',', '').trim(),
    );
    final claim = <String, dynamic>{
      'title': claimTitleController.text.trim(),
      'insurer': selectedInsurer.value,
      'policyNumber': policyNumberController.text.trim(),
      'policyHolder': policyHolderController.text.trim(),
      'policyStartDate': _toIsoDate(startDate.value),
      'policyEndDate': _toIsoDate(endDate.value),
      'patientName': patientNameController.text.trim(),
      'hospitalName': hospitalNameController.text.trim(),
      'amount': amount,
      'admissionDate': _toIsoDate(admissionDate.value),
      'status': 'Submitted',
      'progress': 0.25,
      'date': DateTime.now().toIso8601String(),
      'docsCount': '${uploadedDocuments.length} / 6',
      'documents': uploadedDocuments.map((doc) => doc.toJson()).toList(),
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'daysActive': '1 day',
    };

    try {
      final claimId = await _repository.createClaim(claim);
      Get.snackbar(
        'Claim submitted',
        'Your claim $claimId was saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F766E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      resetForm();
      selectedTab.value = 0;
    } catch (error) {
      _showError('Could not save claim. Please try again. $error');
    } finally {
      isSubmittingClaim.value = false;
    }
  }

  bool _validateAllSteps() =>
      _validateStep(1) && _validateStep(2) && _validateStep(3);

  void prevStep() {
    if (selectedTab.value == 1) {
      if (currentStep.value > 1) {
        currentStep.value--;
      } else {
        selectedTab.value = 0;
      }
    } else if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeNavIndex(0);
    } else {
      Get.back();
    }
  }

  void resetForm() {
    currentStep.value = 1;
    selectedDocumentCategory.value = 'policy';
    uploadedDocuments.clear();
    selectedInsurer.value = '';
    policyNumberController.clear();
    policyHolderController.clear();
    startDate.value = '';
    endDate.value = '';
    claimTitleController.clear();
    patientNameController.clear();
    hospitalNameController.clear();
    claimAmountController.clear();
    admissionDate.value = '';
  }

  Future<void> pickDate(BuildContext context, String targetField) async {
    final today = DateTime.now();
    final start = _parseDate(startDate.value);
    final end = _parseDate(endDate.value);
    DateTime initialDate = today;
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    if (targetField == 'startDate') {
      lastDate = DateTime(2100);
    } else if (targetField == 'endDate') {
      firstDate = start?.add(const Duration(days: 1)) ?? DateTime(2000);
      initialDate = end != null && end.isAfter(firstDate) ? end : firstDate;
    } else if (targetField == 'admissionDate') {
      firstDate = start ?? DateTime(2000);
      lastDate = end ?? today;
      initialDate = today.isBefore(firstDate)
          ? firstDate
          : (today.isAfter(lastDate) ? lastDate : today);
      if (lastDate.isBefore(firstDate)) {
        _showError('Set valid policy start and end dates first.');
        return;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    final formatted = _formatDate(picked);
    if (targetField == 'startDate') {
      startDate.value = formatted;
      final existingEnd = _parseDate(endDate.value);
      if (existingEnd != null && !existingEnd.isAfter(picked)) {
        endDate.value = '';
      }
      final existingAdmission = _parseDate(admissionDate.value);
      if (existingAdmission != null && existingAdmission.isBefore(picked)) {
        admissionDate.value = '';
      }
    } else if (targetField == 'endDate') {
      endDate.value = formatted;
      final existingAdmission = _parseDate(admissionDate.value);
      if (existingAdmission != null && existingAdmission.isAfter(picked)) {
        admissionDate.value = '';
      }
    } else if (targetField == 'admissionDate') {
      admissionDate.value = formatted;
    }
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _toIsoDate(String value) {
    final date = _parseDate(value)!;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showError(String message) => Get.snackbar(
    'Check claim details',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red.shade700,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );

  void _showUploadError(String message) => Get.snackbar(
    'Document upload failed',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red.shade700,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 6),
  );

  @override
  void onClose() {
    _claimsSubscription?.cancel();
    policyNumberController.dispose();
    policyHolderController.dispose();
    claimTitleController.dispose();
    patientNameController.dispose();
    hospitalNameController.dispose();
    claimAmountController.dispose();
    super.onClose();
  }
}
