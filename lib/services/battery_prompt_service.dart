import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_theme.dart';

class BatteryPromptService {
  static final BatteryPromptService instance = BatteryPromptService._internal();
  BatteryPromptService._internal();

  static const int maxPrompts = 3;
  static const String _countKey = 'battery_prompt_count';
  final _storage = GetStorage();

  int get _shownCount => _storage.read(_countKey) ?? 0;

  static const _channel = MethodChannel('routinefix/battery');

  Future<bool> _isUnrestricted() async {
    try {
      return await _channel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// App launch par auto-prompt — total max 3 baar.
  Future<void> maybePromptOnLaunch() async {
    if (await _isUnrestricted()) return;
    if (_shownCount >= maxPrompts) return;
    await _storage.write(_countKey, _shownCount + 1);

    final accepted = await _showExplainerDialog();
    if (accepted == true) {
      await _storage.write(
          _countKey, maxPrompts); // user maan gaya, ab nahi poochna
      await openAppSettings();
    } else {
      Get.snackbar(
        'No problem',
        'You can enable background reminders anytime from Settings → Notifications.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.inkNavy,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Settings se trigger — counter se independent.
  Future<void> promptFromSettings() async {
    if (await _isUnrestricted()) {
      Get.snackbar('All set', 'Background reminders are already enabled.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.inkNavy,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 12);
      return;
    }
    final accepted = await _showExplainerDialog();
    if (accepted == true) await openAppSettings();
  }

  Future<bool?> _showExplainerDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        title: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.inkNavy,
              AppColors.inkNavy.withOpacity(0.88),
            ]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.signalTeal.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: AppColors.signalTeal, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Never miss a reminder',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        content: const Text(
          'Allow RoutineFix to run in the background so your task and occasion '
          'reminders arrive on time — even when your phone is locked.\n\n'
          'On the next screen: Battery → Unrestricted.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Not now')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.signalTeal,
                foregroundColor: Colors.white),
            onPressed: () => Get.back(result: true),
            child: const Text('Yes, allow'),
          ),
        ],
      ),
    );
  }
}
