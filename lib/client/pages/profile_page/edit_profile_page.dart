import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileController controller = Get.find<ProfileController>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: controller.userName);
    _phoneController = TextEditingController(text: controller.phoneNumber.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return;

      setState(() => _isUploadingPhoto = true);
      final success = await controller.updateProfilePhoto(
        bytes: bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

      if (success) {
        Get.snackbar(
          'Photo Updated',
          'Your profile photo has been updated successfully.',
          backgroundColor: const Color(0xFFE6F7F5),
          colorText: const Color(0xFF007A78),
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF007A78)),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isUploadingPhoto = false);
      Get.snackbar(
        'Upload Failed',
        'Could not upload photo: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.updateProfile(
      newName: _nameController.text.trim(),
      newPhone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      Get.back();
      Get.snackbar(
        'profile_updated'.tr,
        'profile_updated_msg'.tr,
        backgroundColor: const Color(0xFFE6F7F5),
        colorText: const Color(0xFF007A78),
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF007A78)),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'edit_profile'.tr,
          style: const TextStyle(
            color: Color(0xFF0F2942),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F2942), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Avatar with interactive badge
              Obx(() {
                final user = controller.currentUser.value;
                final photoUrl = controller.userPhotoUrl.value.isNotEmpty
                    ? controller.userPhotoUrl.value
                    : user?.photoURL;

                return GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      if (photoUrl != null && photoUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(photoUrl),
                        )
                      else
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFE0F2FE),
                          child: Icon(Icons.person_rounded, size: 54, color: Color(0xFF0284C7)),
                        ),
                      if (_isUploadingPhoto)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A78),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                final user = controller.currentUser.value;
                return Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Full Name field
              _buildTextField(
                label: 'full_name'.tr,
                controller: _nameController,
                icon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'name_required'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Phone Number field
              _buildTextField(
                label: 'phone_number'.tr,
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hintText: '+91 98765 43210',
              ),

              const SizedBox(height: 18),

              // Email field (read-only info)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'email_linked'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.currentUser.value?.email ?? 'No email linked',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F2942),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 18),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Save Button
              Obx(() {
                final isSaving = controller.isUpdating.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A78),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'save_changes'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F2942),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFCBD5E1),
          ),
          icon: Icon(icon, color: const Color(0xFF0F2942), size: 22),
        ),
      ),
    );
  }
}
