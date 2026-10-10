import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/claim_document_upload_service.dart';
import '../../../services/claim_repository.dart';

class DocumentModel {
  final String title;
  final String category;
  final int fileCount;
  final String date;
  final String status;
  final IconData icon;
  final List<String> fileNames;
  final List<Map<String, dynamic>> files;
  final String subtitle;

  const DocumentModel({
    required this.title,
    required this.category,
    required this.fileCount,
    required this.date,
    required this.status,
    required this.icon,
    this.fileNames = const [],
    this.files = const [],
    this.subtitle = '',
  });

  bool get isUploaded => status == 'Uploaded';
  bool get isMissing => status == 'Missing';
}

class DocumentsController extends GetxController {
  final RxInt selectedFilterIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxList<DocumentModel> allDocuments = <DocumentModel>[].obs;
  final RxBool isLoadingDocuments = true.obs;
  final RxString uploadingCategory = ''.obs;

  final List<String> filters = const ['All', 'Uploaded', 'Required', 'Missing'];

  late final ClaimRepository _repository;
  StreamSubscription<List<Map<String, dynamic>>>? _documentsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _claimsSubscription;
  List<Map<String, dynamic>> _documentRecords = [];
  List<Map<String, dynamic>> _claims = [];
  bool _receivedDocuments = false;
  bool _receivedClaims = false;

  @override
  void onInit() {
    super.onInit();
    _repository = Get.isRegistered<ClaimRepository>()
        ? Get.find<ClaimRepository>()
        : Get.put(ClaimRepository(), permanent: true);
    _documentsSubscription = _repository.watchDocuments().listen(
      (records) {
        _documentRecords = records;
        _receivedDocuments = true;
        _updateLoadingState();
        _rebuildDocuments();
      },
      onError: (Object error) {
        _receivedDocuments = true;
        _updateLoadingState();
        Get.snackbar(
          'Documents unavailable',
          'Could not load your uploaded documents: $error',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
    _claimsSubscription = _repository.watchClaims().listen(
      (claims) {
        _claims = claims;
        _receivedClaims = true;
        _updateLoadingState();
        _rebuildDocuments();
      },
      onError: (Object error) {
        _receivedClaims = true;
        _updateLoadingState();
        Get.snackbar(
          'Documents unavailable',
          'Could not load claim document suggestions: $error',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  void _updateLoadingState() {
    isLoadingDocuments.value = !(_receivedDocuments && _receivedClaims);
  }

  void _rebuildDocuments() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final record in _documentRecords) {
      final category = (record['category'] ?? 'other').toString();
      grouped.putIfAbsent(category, () => []).add(record);
    }

    final documents = grouped.entries.map((entry) {
      final categoryInfo = _categoryInfo(entry.key);
      final files = entry.value;
      final latestUpload = files
          .map((file) => file['uploadedAt'])
          .whereType<num>()
          .fold<num?>(
            null,
            (latest, value) =>
                latest == null || value > latest ? value : latest,
          );
      return DocumentModel(
        title: categoryInfo.$1,
        category: entry.key,
        fileCount: files.length,
        date: latestUpload == null
            ? ''
            : _formatDate(
                DateTime.fromMillisecondsSinceEpoch(latestUpload.toInt()),
              ),
        status: 'Uploaded',
        icon: categoryInfo.$2,
        files: files,
        fileNames: files
            .map((file) => (file['fileName'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toList(),
      );
    }).toList();

    final uploadedCategories = grouped.keys.toSet();
    final missingSuggestions = <String, List<String>>{};
    for (final claim in _claims) {
      final review = claim['aiReview'];
      if (review is! Map) continue;
      final value = review['suggestedDocuments'];
      final suggestions = value is List
          ? value
          : value is Map
          ? value.values.toList()
          : const <dynamic>[];
      for (final item in suggestions.whereType<Map>()) {
        final category = (item['category'] ?? '').toString();
        if (category.isEmpty || uploadedCategories.contains(category)) continue;
        final categoryTitle = (item['title'] ?? _categoryInfo(category).$1)
            .toString();
        final claimTitle = (claim['title'] ?? 'Health Claim').toString();
        final reason = (item['reason'] ?? '').toString();
        final detail = reason.isEmpty
            ? 'Suggested for $claimTitle'
            : 'Suggested for $claimTitle: $reason';
        final lines = missingSuggestions.putIfAbsent(category, () => []);
        if (!lines.contains('$categoryTitle|$detail')) {
          lines.add('$categoryTitle|$detail');
        }
      }
    }
    for (final entry in missingSuggestions.entries) {
      final categoryInfo = _categoryInfo(entry.key);
      final suggestions = entry.value.map((value) => value.split('|'));
      final title = suggestions.first.first;
      final subtitle = suggestions.map((parts) => parts.last).join('\n');
      documents.add(
        DocumentModel(
          title: title,
          category: entry.key,
          fileCount: 0,
          date: '',
          status: 'Missing',
          icon: categoryInfo.$2,
          subtitle: subtitle,
        ),
      );
    }
    documents.sort((a, b) => a.title.compareTo(b.title));
    allDocuments.assignAll(documents);
  }

  (String, IconData) _categoryInfo(String category) {
    switch (category) {
      case 'policy':
        return ('Policy Document', Icons.shield_outlined);
      case 'hospital_bills':
        return ('Medical Bills', Icons.receipt_long_outlined);
      case 'discharge_summary':
        return ('Hospital Discharge Summary', Icons.local_hospital_outlined);
      case 'prescription':
        return ('Prescription', Icons.note_alt_outlined);
      case 'medical_reports':
        return ('Medical Reports', Icons.biotech_outlined);
      case 'insurer_letters':
        return ('Insurer Letters', Icons.mail_outline_rounded);
      default:
        return ('Other Documents', Icons.more_horiz_rounded);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${_monthName(date.month)} ${date.year}';

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  List<DocumentModel> get filteredDocuments {
    final query = searchQuery.value.toLowerCase().trim();
    final currentFilter = filters[selectedFilterIndex.value];

    return allDocuments.where((doc) {
      final matchesQuery =
          query.isEmpty ||
          doc.title.toLowerCase().contains(query) ||
          doc.subtitle.toLowerCase().contains(query) ||
          doc.fileNames.any((name) => name.toLowerCase().contains(query));
      if (!matchesQuery) return false;
      if (currentFilter == 'All') return true;
      if (currentFilter == 'Uploaded') {
        return doc.isUploaded;
      }
      if (currentFilter == 'Required') return doc.category == 'policy';
      return doc.isMissing;
    }).toList();
  }

  void setFilter(int index) => selectedFilterIndex.value = index;
  void updateSearch(String query) => searchQuery.value = query;

  Future<void> openDocument(DocumentModel document) async {
    if (uploadingCategory.value == document.category) return;
    if (document.isMissing) {
      await _uploadMissingDocument(document.category);
      return;
    }
    if (!document.isUploaded || document.files.isEmpty) return;

    Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.65),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                document.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${document.files.length} uploaded ${document.files.length == 1 ? 'file' : 'files'}',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: document.files.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = document.files[index];
                    final name = (file['fileName'] ?? 'Document').toString();
                    final url = (file['documentUrl'] ?? '').toString();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF15808D),
                      ),
                      title: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _uploadedDate(file['uploadedAt']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: Color(0xFF15808D),
                      ),
                      onTap: () => _openDocumentUrl(url),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _uploadMissingDocument(String category) async {
    uploadingCategory.value = category;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final selected = result.files.single;
      final bytes = selected.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw StateError(
          'Could not read the selected file. Please select it again.',
        );
      }
      if (selected.size > 10 * 1024 * 1024) {
        throw StateError('Choose a file smaller than 10 MB.');
      }

      final uploadService = Get.isRegistered<ClaimDocumentUploadService>()
          ? Get.find<ClaimDocumentUploadService>()
          : Get.put(ClaimDocumentUploadService(), permanent: true);
      final uploaded = await uploadService.upload(
        fileName: selected.name,
        bytes: bytes,
        category: category,
      );
      await _repository.saveUploadedDocument(uploaded.toJson());
      Get.snackbar(
        'Document uploaded',
        '${selected.name} is now available in this category.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Upload failed',
        error.toString().replaceFirst('Bad state: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      uploadingCategory.value = '';
    }
  }

  Future<void> _openDocumentUrl(String value) async {
    final uri = Uri.tryParse(value);
    final isCloudinaryUrl =
        uri != null &&
        uri.scheme == 'https' &&
        (uri.host == 'cloudinary.com' || uri.host.endsWith('.cloudinary.com'));
    if (!isCloudinaryUrl) {
      Get.snackbar(
        'Document unavailable',
        'This file does not have a valid Cloudinary link.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      Get.snackbar(
        'Could not open document',
        'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _uploadedDate(dynamic value) {
    if (value is! num) return '';
    return _formatDate(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
  }

  @override
  void onClose() {
    _documentsSubscription?.cancel();
    _claimsSubscription?.cancel();
    super.onClose();
  }
}
