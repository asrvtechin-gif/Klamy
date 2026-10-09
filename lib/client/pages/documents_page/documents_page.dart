import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'documents_controller.dart';

class DocumentsPage extends StatelessWidget {
  DocumentsPage({super.key});

  final DocumentsController controller = Get.find<DocumentsController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Documents Vault',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 16),

          // Search Input Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: controller.updateSearch,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F2942),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search documents...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips Row
          SizedBox(
            height: 38,
            child: Obx(() {
              final selectedIndex = controller.selectedFilterIndex.value;
              final filterList = controller.filters;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterList.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () => controller.setFilter(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF15808D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF15808D)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        filterList[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 20),

          // Document Cards List
          Expanded(
            child: Obx(() {
              // Explicitly trigger reactive tracking on selected filter & search query
              final selectedFilter = controller.selectedFilterIndex.value;
              final query = controller.searchQuery.value;
              debugPrint('Filter: $selectedFilter, Query: $query');

              final docs = controller.filteredDocuments;

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No documents found',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left Icon Container
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            doc.icon,
                            color: const Color(0xFF0F766E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2942),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doc.fileCount > 0
                                    ? '${doc.fileCount} ${doc.fileCount == 1 ? 'file' : 'files'}  •  ${doc.date}'
                                    : '0 file',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        _buildStatusBadge(doc),

                        const SizedBox(width: 8),

                        // Chevron Arrow
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 12),

          // Upload Document Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: controller.uploadDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15808D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: const Icon(
                Icons.cloud_upload_outlined,
                size: 22,
                color: Colors.white,
              ),
              label: const Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DocumentModel doc) {
    if (doc.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF16A34A),
            ),
            SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_rounded,
            size: 14,
            color: Color(0xFFDC2626),
          ),
          SizedBox(width: 4),
          Text(
            'Missing',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
