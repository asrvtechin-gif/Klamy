import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_page/home_controller.dart';

class ClaimsController extends GetxController {
  final RxInt currentStep = 1.obs; // 1: Policy Details, 2: Claim Details, 3: Documents, 4: Review

  final RxString selectedInsurer = ''.obs;
  final TextEditingController policyNumberController = TextEditingController();
  final TextEditingController policyHolderController = TextEditingController();

  final RxString startDate = ''.obs;
  final RxString endDate = ''.obs;

  final List<String> insurers = const [
    'Star Health Insurance',
    'HDFC ERGO Health',
    'ICICI Lombard',
    'Care Health Insurance',
    'Niva Bupa Health Insurance',
    'Aditya Birla Health Insurance',
  ];

  void setInsurer(String? value) {
    if (value != null) {
      selectedInsurer.value = value;
    }
  }

  void nextStep() {
    if (currentStep.value < 4) {
      currentStep.value++;
    } else {
      Get.snackbar(
        'Claim Created',
        'Your claim has been submitted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF0F2942),
      );
    }
  }

  void prevStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    } else {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().changeNavIndex(0);
      } else {
        Get.back();
      }
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      if (isStart) {
        startDate.value = formatted;
      } else {
        endDate.value = formatted;
      }
    }
  }

  @override
  void onClose() {
    policyNumberController.dispose();
    policyHolderController.dispose();
    super.onClose();
  }
}
