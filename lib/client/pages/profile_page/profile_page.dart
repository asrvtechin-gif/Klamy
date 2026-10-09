import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (user?.photoURL != null && user!.photoURL!.isNotEmpty)
              CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(user.photoURL!),
              )
            else
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.person, size: 48, color: Color(0xFF0284C7)),
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
            const SizedBox(height: 32),

            // Profile Tile Options
            _buildProfileTile(Icons.person_outline_rounded, 'Personal Details'),
            _buildProfileTile(Icons.security_outlined, 'Security & Privacy'),
            _buildProfileTile(Icons.notifications_none_rounded, 'Notification Preferences'),
            _buildProfileTile(Icons.help_outline_rounded, 'Help & Support'),

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
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
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

  Widget _buildProfileTile(IconData icon, String title) {
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
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: () {},
      ),
    );
  }
}
