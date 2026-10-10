import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/skeleton_box.dart';
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
          Text(
            'document_vault'.tr,
            style: const TextStyle(
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
                    decoration: InputDecoration(
                      hintText: 'search_docs'.tr,
                      hintStyle: const TextStyle(
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
                        horizontal: 20,
                        vertical: 8,
                      ),
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

              if (controller.isLoadingDocuments.value) {
                return ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: const Row(
                      children: [
                        SkeletonBox(width: 42, height: 42, radius: 12),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 150, height: 12),
                              SizedBox(height: 8),
                              SkeletonBox(width: 90, height: 10),
                            ],
                          ),
                        ),
                        SkeletonBox(width: 62, height: 22, radius: 12),
                      ],
                    ),
                  ),
                );
              }

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
                  final isUploading =
                      controller.uploadingCategory.value == doc.category;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isUploading
                          ? null
                          : () => controller.openDocument(doc),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                                        ? '${doc.fileCount} ${doc.fileCount == 1 ? 'file' : 'files'}${doc.date.isEmpty ? '' : '  •  ${doc.date}'}'
                                        : 'Suggested by Klamy',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  if (doc.subtitle.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        doc.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  if (doc.fileNames.isNotEmpty)
                                    Text(
                                      doc.fileNames.join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Status Badge
                            _buildStatusBadge(doc, isUploading: isUploading),

                            const SizedBox(width: 8),

                            // Chevron Arrow
                            isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF15808D),
                                    ),
                                  )
                                : Icon(
                                    doc.isMissing
                                        ? Icons.file_upload_outlined
                                        : Icons.chevron_right_rounded,
                                    color: const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DocumentModel doc, {required bool isUploading}) {
    if (isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'uploading'.tr,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F766E),
          ),
        ),
      );
    }

    if (doc.isUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF16A34A),
            ),
            const SizedBox(width: 4),
            Text(
              'uploaded'.tr,
              style: const TextStyle(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_rounded, size: 14, color: Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Text(
            'missing'.tr,
            style: const TextStyle(
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
