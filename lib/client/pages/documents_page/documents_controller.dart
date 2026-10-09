import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DocumentModel {
  final String title;
  final int fileCount;
  final String date;
  final String status;
  final IconData icon;

  const DocumentModel({
    required this.title,
    required this.fileCount,
    required this.date,
    required this.status,
    required this.icon,
  });

  bool get isVerified => status == 'Verified';
  bool get isMissing => status == 'Missing';
}

class DocumentsController extends GetxController {
  final RxInt selectedFilterIndex = 0.obs;
  final RxString searchQuery = ''.obs;

  final List<String> filters = const ['All', 'Uploaded', 'Required', 'Missing'];

  final RxList<DocumentModel> allDocuments = <DocumentModel>[
    const DocumentModel(
      title: 'Medical Bills',
      fileCount: 2,
      date: '12 Mar 2025',
      status: 'Verified',
      icon: Icons.receipt_long_outlined,
    ),
    const DocumentModel(
      title: 'Prescription',
      fileCount: 1,
      date: '10 Mar 2025',
      status: 'Verified',
      icon: Icons.note_alt_outlined,
    ),
    const DocumentModel(
      title: 'Hospital Discharge Summary',
      fileCount: 1,
      date: '8 Mar 2025',
      status: 'Verified',
      icon: Icons.local_hospital_outlined,
    ),
    const DocumentModel(
      title: 'Policy Document',
      fileCount: 1,
      date: '5 Mar 2025',
      status: 'Verified',
      icon: Icons.shield_outlined,
    ),
    const DocumentModel(
      title: 'ID Proof',
      fileCount: 1,
      date: '2 Mar 2025',
      status: 'Verified',
      icon: Icons.badge_outlined,
    ),
    const DocumentModel(
      title: 'Other Documents',
      fileCount: 0,
      date: '',
      status: 'Missing',
      icon: Icons.more_horiz_rounded,
    ),
  ].obs;

  List<DocumentModel> get filteredDocuments {
    final query = searchQuery.value.toLowerCase().trim();
    final currentFilter = filters[selectedFilterIndex.value];

    return allDocuments.where((doc) {
      final matchesQuery = query.isEmpty || doc.title.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (currentFilter == 'All') return true;
      if (currentFilter == 'Uploaded' || currentFilter == 'Required') {
        return doc.status == 'Verified';
      }
      if (currentFilter == 'Missing') {
        return doc.status == 'Missing';
      }
      return true;
    }).toList();
  }

  void setFilter(int index) {
    selectedFilterIndex.value = index;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void uploadDocument() {
    Get.snackbar(
      'Upload Document',
      'Select a file from your device...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF0F2942),
      margin: const EdgeInsets.all(16),
    );
  }
}
