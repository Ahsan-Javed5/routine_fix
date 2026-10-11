import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_theme.dart';

class CustomSnackbar {
  CustomSnackbar._();

  static DateTime? _shownAt;

  static void error(
    String title,
    String message, {
    IconData? icon,
    Duration? duration,
    SnackPosition? position,
  }) {
    _show(
      title: title,
      message: message,
      accent: AppColors.emberCoral,
      icon: icon ?? Icons.error_outline_rounded,
      duration: duration ?? const Duration(seconds: 4),
      position: position,
    );
  }

  static void success(
    String title,
    String message, {
    IconData? icon,
    Duration? duration,
    SnackPosition? position,
  }) {
    _show(
      title: title,
      message: message,
      accent: AppColors.signalTeal,
      icon: icon ?? Icons.check_circle_outline_rounded,
      duration: duration ?? const Duration(seconds: 3),
      position: position,
    );
  }

  static void info(
    String title,
    String message, {
    IconData? icon,
    Duration? duration,
    SnackPosition? position,
  }) {
    _show(
      title: title,
      message: message,
      accent: AppColors.amberGold,
      icon: icon ?? Icons.info_outline_rounded,
      duration: duration ?? const Duration(seconds: 3),
      position: position,
    );
  }

  /// Currently visible snackbar (aur queue) foran band kar deta hai.
  static void dismiss() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
  }

  static void onRouteChange(Routing? routing) {
    final shownAt = _shownAt;
    if (shownAt != null &&
        DateTime.now().difference(shownAt) <
            const Duration(milliseconds: 600)) {
      return;
    }
    dismiss();
  }

  static Future<void> _show({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
    required Duration duration,
    SnackPosition? position,
  }) async {
    if (Get.isSnackbarOpen) {
      await Get.closeCurrentSnackbar();
    }
    _shownAt = DateTime.now();

    Get.snackbar(
      title,
      message,
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
      ),
      icon: Icon(icon, color: accent, size: 26),
      shouldIconPulse: false,
      leftBarIndicatorColor: accent,
      backgroundColor: AppColors.inkNavy,
      borderColor: accent.withOpacity(0.6),
      borderWidth: 1,
      borderRadius: 14,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      snackPosition: position ?? SnackPosition.TOP,
      duration: duration,
      isDismissible: true,
      barBlur: 0,
      overlayBlur: 0,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
