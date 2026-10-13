import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:routine_fix/utils/custom_snackbar.dart';
import '../controllers/task_controller.dart';
import '../utils/app_theme.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  static final String _rewardedUnitId = kReleaseMode
      ? (dotenv.env['ADMOB_UNIT_ID'] ?? '') // real (release)
      : 'ca-app-pub-3940256099942544/5224354917'; // Google test ID (debug)

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void preload() {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  Future<bool> showForAiCredit() async {
    final controller = Get.find<TaskController>();
    if (!controller.canWatchAdForCredit) return false;

    final ad = _rewardedAd;
    if (ad == null) {
      preload();
      CustomSnackbar.info(
        'Ad not ready',
        'Please try again in a few seconds.',
      );
      return false;
    }
    _rewardedAd = null;

    final completer = Completer<bool>();
    bool rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(onUserEarnedReward: (_, reward) {
      rewarded = true;
      controller.grantAdBonus();
    });

    return completer.future;
  }
}
