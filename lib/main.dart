import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'controllers/theme_controller.dart';
import 'services/db_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await DbService.instance.init();
  await NotificationService.instance.init();

  // Schedule today's nightly nudges once at app start.
  await NotificationService.instance.scheduleNightlyNudges(DateTime.now());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController(), permanent: true);
    return Obx(() => GetMaterialApp(
          title: 'RoutineFix',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.themeMode.value.toThemeMode(),
          initialRoute: AppRoutes.home,
          initialBinding: InitialBinding(),
          getPages: AppPages.pages,
        ));
  }
}
