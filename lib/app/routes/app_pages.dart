import 'package:get/get.dart';
import 'app_routes.dart';
import '../../views/main_nav/main_nav_view.dart';
import '../../views/add_task/add_task_view.dart';
import '../../views/occasional_reminder/occasional_view.dart';
import '../../views/reports/reports_view.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.home, page: () => const MainNavView()),
    GetPage(name: AppRoutes.addTask, page: () => const AddTaskView()),
    GetPage(name: AppRoutes.occasionalReminder, page: () => const OccasionalView()),
    GetPage(name: AppRoutes.reports, page: () => const ReportsView()),
  ];
}
