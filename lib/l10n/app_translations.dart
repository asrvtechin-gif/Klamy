import 'package:get/get.dart';
import 'app_strings.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'hi_IN': hi,
      };
}
