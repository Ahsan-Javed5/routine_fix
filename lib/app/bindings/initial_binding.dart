import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/reminder_controller.dart';
import '../../controllers/report_controller.dart';
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ThemeController is registered in main.dart before GetMaterialApp builds.
    Get.put(TaskController(), permanent: true);
    Get.put(ReminderController(), permanent: true);
    Get.lazyPut(() => ReportController());
  }
}
