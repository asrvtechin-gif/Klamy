import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../auth/login_page/login_page.dart';
import '../actions_page/actions_controller.dart';
import '../claims_page/claims_controller.dart';
import '../documents_page/documents_controller.dart';
import '../notification_page/notification_controller.dart';
import '../profile_page/profile_controller.dart';

class HomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxInt selectedNavIndex = 0.obs;
  DateTime? lastBackPressed;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    currentUser.bindStream(_auth.authStateChanges());

    Get.lazyPut(() => DocumentsController());
    Get.lazyPut(() => ClaimsController());
    Get.lazyPut(() => ActionsController());
    Get.lazyPut(() => ProfileController());
    Get.put(NotificationController(), permanent: true);
  }

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  String get userName {
    final user = currentUser.value;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return 'Shubham Singh';
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Future<void> signOut() async {
    try {
      if (Get.isRegistered<NotificationController>()) {
        await Get.find<NotificationController>().unregisterCurrentDevice();
      }
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
