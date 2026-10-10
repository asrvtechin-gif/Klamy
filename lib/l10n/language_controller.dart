import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  static const _prefKey = 'app_language';
  final RxString currentLangCode = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  bool get isHindi => currentLangCode.value == 'hi';

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey) ?? 'en';
      currentLangCode.value = saved;
      _applyLocale(saved);
    } catch (_) {}
  }

  Future<void> switchLanguage(String langCode) async {
    if (currentLangCode.value == langCode) return;
    currentLangCode.value = langCode;
    _applyLocale(langCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (_) {}
    Get.snackbar(
      'language_applied'.tr,
      'lang_apply_desc'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _applyLocale(String langCode) {
    switch (langCode) {
      case 'hi':
        Get.updateLocale(const Locale('hi', 'IN'));
        break;
      default:
        Get.updateLocale(const Locale('en', 'US'));
    }
  }

  String get displayName => isHindi ? 'हिन्दी' : 'English';
}
