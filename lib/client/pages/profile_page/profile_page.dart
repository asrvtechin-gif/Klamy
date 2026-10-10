import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/language_controller.dart';
import '../legal/privacy_policy_page.dart';
import '../legal/terms_page.dart';
import '../notification_page/notification_page.dart';
import 'edit_profile_page.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      final photoUrl = controller.userPhotoUrl.value.isNotEmpty
          ? controller.userPhotoUrl.value
          : user?.photoURL;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Get.to(() => const EditProfilePage()),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: NetworkImage(photoUrl),
                    )
                  else
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(Icons.person, size: 48, color: Color(0xFF0284C7)),
                    ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A78),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2942),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'user@klamy.in',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Tile Options
            _buildProfileTile(
              Icons.person_outline_rounded,
              'personal_details'.tr,
              onTap: () => Get.to(() => const EditProfilePage()),
            ),
            Obx(() => _buildProfileTile(
              Icons.translate_rounded,
              'language_preference'.tr,
              subtitle: Get.find<LanguageController>().displayName,
              onTap: () => _showLanguageDialog(context),
            )),
            _buildProfileTile(
              Icons.shield_outlined,
              'privacy_policy'.tr,
              onTap: () => Get.to(() => const PrivacyPolicyPage()),
            ),
            _buildProfileTile(
              Icons.description_outlined,
              'terms_conditions'.tr,
              onTap: () => Get.to(() => const TermsAndConditionsPage()),
            ),
            _buildProfileTile(
              Icons.notifications_none_rounded,
              'notification_prefs'.tr,
              onTap: () => Get.to(() => NotificationPage()),
            ),
            _buildProfileTile(
              Icons.support_agent_rounded,
              'contact_us'.tr,
              subtitle: 'asrvtech.in@gmail.in',
              onTap: () => _showHelpDialog(context),
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: controller.signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1F2),
                  foregroundColor: const Color(0xFFE11D48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
                label: Text(
                  'sign_out'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showLanguageDialog(BuildContext context) {
    final langController = Get.find<LanguageController>();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.translate_rounded, color: Color(0xFF007A78), size: 26),
                const SizedBox(width: 12),
                Text(
                  'select_language'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              final current = langController.currentLangCode.value;
              return Column(
                children: [
                  _buildLanguageOption(
                    title: 'English',
                    subtitle: 'Default language',
                    isSelected: current == 'en',
                    onTap: () {
                      langController.switchLanguage('en');
                      Get.back();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageOption(
                    title: 'हिन्दी (Hindi)',
                    subtitle: 'हिन्दी भाषा चुनें',
                    isSelected: current == 'hi',
                    onTap: () {
                      langController.switchLanguage('hi');
                      Get.back();
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F7F5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF007A78) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF007A78) : const Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF007A78) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF007A78), size: 24)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 24),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: Color(0xFF007A78), size: 28),
                SizedBox(width: 12),
                Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Need assistance with your health claims, policy documents, or local AI assistant?',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      const email = 'asrvtech.in@gmail.in';
                      final uri = Uri.parse('mailto:$email');
                      try {
                        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!ok) throw Exception();
                      } catch (_) {
                        await Clipboard.setData(const ClipboardData(text: email));
                        Get.snackbar(
                          'Email Copied',
                          'Support email $email copied to clipboard.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF0F766E),
                          colorText: Colors.white,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, color: Color(0xFF007A78), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'asrvtech.in@gmail.in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F2942),
                              ),
                            ),
                          ),
                          Icon(Icons.open_in_new_rounded, color: Color(0xFF64748B), size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.language_rounded, color: Color(0xFF007A78), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'https://klamy-8789e.web.app',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A78),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F2942)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2942),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF007A78),
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
