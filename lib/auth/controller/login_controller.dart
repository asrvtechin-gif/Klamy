import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../client/pages/home_page/home_page.dart';

class OnboardingSlide {
  final String title;
  final String subtitle;
  final String? imageUrl;

  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });
}

class LoginController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final RxBool isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<OnboardingSlide> slides = const [
    OnboardingSlide(
      title: 'Klamy',
      subtitle: 'Organize Every Document. Know whats missing before you submit.',
      imageUrl: 'assets/image/image1.jpeg',
    ),
    OnboardingSlide(
      title: '',
      subtitle: 'Understand Every Decision. Make sense of claim deductions and rejections.',
      imageUrl: 'assets/image/image2.jpeg',
    ),
    OnboardingSlide(
      title: '',
      subtitle: 'Never Miss a Step. Track claim progress, deadlines, and next actions.',
      imageUrl: 'assets/image/image3.jpeg',
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // 1. Trigger Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled sign-in
        isLoading.value = false;
        return;
      }

      // 2. Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        // 5. Save/update user profile in Firebase Firestore Backend
        await _saveUserToFirestore(user);

        Get.snackbar(
          'Welcome ${user.displayName ?? ""}',
          'Signed in successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
          colorText: Colors.black,
          margin: const EdgeInsets.all(16),
        );

        // Navigate to HomePage
        Get.offAll(() => HomePage());
      }
    } catch (e) {
      Get.snackbar(
        'Sign-In Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Firestore Error: $e');
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
