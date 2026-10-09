import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'actions_controller.dart';

class ActionsPage extends StatelessWidget {
  ActionsPage({super.key});

  final ActionsController controller = Get.find<ActionsController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete these tasks to speed up claim approval.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(() {
              final taskList = controller.tasks;

              return ListView.builder(
                itemCount: taskList.length,
                itemBuilder: (context, index) {
                  final task = taskList[index];
                  return InkWell(
                    onTap: () => controller.toggleTask(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: task.isCompleted.value
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted.value
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: task.isCompleted.value
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF00A3A1),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: task.isCompleted.value
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF0F2942),
                                decoration: task.isCompleted.value
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
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
}
