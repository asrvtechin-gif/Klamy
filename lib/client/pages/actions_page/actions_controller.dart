import 'package:get/get.dart';

class ActionTask {
  final String title;
  final RxBool isCompleted;

  ActionTask({required this.title, bool completed = false})
      : isCompleted = completed.obs;
}

class ActionsController extends GetxController {
  final RxList<ActionTask> tasks = <ActionTask>[
    ActionTask(title: 'Upload Missing MRI Scan Report'),
    ActionTask(title: 'Verify Health Insurance Policy Number'),
    ActionTask(title: 'Submit Final Discharge Summary with GST Invoice'),
    ActionTask(title: 'Confirm Bank Account Details for Settlement'),
  ].obs;

  void toggleTask(int index) {
    tasks[index].isCompleted.toggle();
    Get.snackbar(
      'Task Updated',
      tasks[index].isCompleted.value ? 'Task completed' : 'Task pending',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }
}
