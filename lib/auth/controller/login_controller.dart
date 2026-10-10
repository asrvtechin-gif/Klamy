import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

      // Firebase Auth's popup flow is the supported Google sign-in path on web.
      // The google_sign_in package flow remains in use for Android and iOS.
      final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

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
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'unauthorized-domain' =>
          'This website domain is not authorized for sign-in. Add it under Firebase Authentication > Settings > Authorized domains.',
        'popup-blocked' =>
          'The sign-in popup was blocked by your browser. Allow popups and try again.',
        'popup-closed-by-user' => 'Sign-in was cancelled.',
        _ => e.message ?? e.code,
      };
      Get.snackbar(
        'Sign-In Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
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
