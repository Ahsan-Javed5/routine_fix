import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum ThemeModeOption { light, dark, system }

extension ThemeModeOptionX on ThemeModeOption {
  ThemeMode toThemeMode() {
    switch (this) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  String get label {
    switch (this) {
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
      case ThemeModeOption.system:
        return 'System Default';
    }
  }
}

class ThemeController extends GetxController {
  final _box = GetStorage();
  static const _key = 'themeMode';

  final Rx<ThemeModeOption> themeMode = ThemeModeOption.system.obs;

  @override
  void onInit() {
    super.onInit();
    final saved = _box.read(_key);
    if (saved != null) {
      themeMode.value = ThemeModeOption.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeModeOption.system,
      );
    }
  }

  void setMode(ThemeModeOption mode) {
    themeMode.value = mode;
    _box.write(_key, mode.name);
    Get.changeThemeMode(mode.toThemeMode());
  }
}
