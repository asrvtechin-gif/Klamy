import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../auth/login_page/login_page.dart';
import '../../../services/claim_document_upload_service.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString phoneNumber = ''.obs;
  final RxString userPhotoUrl = ''.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    currentUser.bindStream(_auth.authStateChanges());
    loadUserProfile();
  }

  String get userName {
    final user = currentUser.value;
    if (user != null && user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    return 'Shubham Singh';
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      userPhotoUrl.value = user.photoURL!;
    }
    try {
      final snapshot = await _database.ref('users/${user.uid}/profile').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (data['phone'] != null) {
          phoneNumber.value = data['phone'].toString();
        }
        if (data['photoURL'] != null && data['photoURL'].toString().isNotEmpty) {
          userPhotoUrl.value = data['photoURL'].toString();
        }
      }
    } catch (_) {
      // Profile details in Realtime Database may not exist yet
    }
  }

  Future<bool> updateProfilePhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    isUpdating.value = true;
    try {
      final uploadService = Get.isRegistered<ClaimDocumentUploadService>()
          ? Get.find<ClaimDocumentUploadService>()
          : Get.put(ClaimDocumentUploadService(), permanent: true);

      final uploaded = await uploadService.upload(
        fileName: fileName,
        bytes: bytes,
        category: 'profile',
      );

      final photoUrl = uploaded.documentUrl;
      await user.updatePhotoURL(photoUrl);

      await _database.ref('users/${user.uid}/profile').update({
        'photoURL': photoUrl,
        'updatedAt': ServerValue.timestamp,
      });

      userPhotoUrl.value = photoUrl;
      await user.reload();
      currentUser.value = _auth.currentUser;
      return true;
    } catch (e) {
      Get.snackbar(
        'Photo Upload Failed',
        'Could not update photo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateProfile({
    required String newName,
    String? newPhone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    isUpdating.value = true;
    try {
      final cleanName = newName.trim();
      final cleanPhone = newPhone?.trim() ?? '';

      // Update Firebase Auth display name
      if (cleanName.isNotEmpty && cleanName != user.displayName) {
        await user.updateDisplayName(cleanName);
      }

      // Update Firebase Realtime Database
      await _database.ref('users/${user.uid}/profile').update({
        'displayName': cleanName,
        'phone': cleanPhone,
        'email': user.email ?? '',
        'updatedAt': ServerValue.timestamp,
      });

      phoneNumber.value = cleanPhone;
      await user.reload();
      currentUser.value = _auth.currentUser;
      return true;
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Could not update profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Sign out failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
