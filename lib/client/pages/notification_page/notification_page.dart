import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_page/home_controller.dart';
import 'notification_controller.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  final NotificationController controller = Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF0F2942),
            size: 24,
          ),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final unread = controller.unreadCount;
          return Row(
            children: [
              Text(
                'notifications'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A3A1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Enable push notifications',
            onPressed: () async {
              final granted = await controller.requestNotificationsPermission();
              Get.snackbar(
                granted ? 'Notifications enabled' : 'Notifications not enabled',
                granted
                    ? 'Klamy can now alert you about claim updates.'
                    : 'Allow notifications in your device settings to receive updates.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF0F2942),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F2942)),
            onSelected: (value) {
              if (value == 'mark_read') {
                controller.markAllAsRead();
              } else if (value == 'clear_all') {
                controller.clearAll();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'mark_read',
                child: Row(
                  children: [
                    const Icon(
                      Icons.done_all_rounded,
                      size: 18,
                      color: Color(0xFF0F2942),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mark_all_read'.tr,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFE11D48),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'clear_all'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return Obx(() {
                  final isSelected =
                      controller.selectedFilter.value == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => controller.setFilter(category),
                      selectedColor: const Color(0xFF0F2942),
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0F2942)
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Notifications List View
          Expanded(
            child: Obx(() {
              final list = controller.filteredNotifications;

              if (list.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _buildNotificationCard(context, item);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You\'re all caught up! No notifications in this section.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final String id = (item['id'] ?? '').toString();
    final bool isRead = item['isRead'] ?? true;
    final category = (item['category'] ?? 'System').toString();
    final IconData icon = switch (category) {
      'Claims' => Icons.verified_user_outlined,
      'Reminders' => Icons.add_task_rounded,
      _ => Icons.notifications_none_rounded,
    };
    final Color bgColor = switch (category) {
      'Claims' => const Color(0xFFE0F2FE),
      'Reminders' => const Color(0xFFFEF3C7),
      _ => const Color(0xFFDCFCE7),
    };
    final Color fgColor = switch (category) {
      'Claims' => const Color(0xFF0284C7),
      'Reminders' => const Color(0xFFD97706),
      _ => const Color(0xFF16A34A),
    };

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.deleteNotification(id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? const Color(0xFFF1F5F9) : const Color(0xFFB0E5E0),
            width: isRead ? 1 : 1.5,
          ),
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
            onTap: () async {
              final actionTab = (item['actionTab'] as num?)?.toInt();
              final homeController =
                  actionTab != null && Get.isRegistered<HomeController>()
                  ? Get.find<HomeController>()
                  : null;
              final route = ModalRoute.of(context);
              final navigator = route?.navigator;
              await controller.markAsRead(id);
              if (actionTab != null && homeController != null) {
                navigator?.pop();
                if (route != null) {
                  route.completed.then((_) {
                    homeController.changeNavIndex(actionTab);
                  });
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: fgColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (item['title'] ?? 'Notification').toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: const Color(0xFF0F2942),
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00A3A1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (item['body'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(item['createdAt']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic value) {
    if (value is! num) return '';
    final createdAt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    final elapsed = DateTime.now().difference(createdAt);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} mins ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours} hours ago';
    if (elapsed.inDays == 1) return 'Yesterday';
    return '${elapsed.inDays} days ago';
  }
}
