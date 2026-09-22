import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles AdMob initialization and ad loading (banner + interstitial).
///
/// Uses Google's official TEST ad unit IDs automatically in debug mode,
/// and the real FitGenie ad unit IDs only in release builds. This avoids
/// accidentally serving/clicking real ads during development, which can
/// get an AdMob account suspended for invalid traffic.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ---- Banner ----
  String get bannerAdUnitId {
    if (kDebugMode) {
      // Google's official test banner ID
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-8397637614188934/1553968781';
    }
    throw UnsupportedError('Unsupported platform for banner ads');
  }

  BannerAd createBannerAd({required void Function(Ad ad) onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  // ---- Interstitial ----
  String get interstitialAdUnitId {
    if (kDebugMode) {
      // Google's official test interstitial ID
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-8397637614188934/7199855166';
    }
    throw UnsupportedError('Unsupported platform for interstitial ads');
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  /// Call this ahead of time (e.g. when a screen opens) so the ad is
  /// ready by the time you actually want to show it.
  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Shows the interstitial if one is ready, then preloads the next one.
  /// Safe to call even if no ad is loaded yet — it just does nothing.
  void showInterstitialAd({void Function()? onDismissed}) {
    final ad = _interstitialAd;
    if (ad == null) {
      onDismissed?.call();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // preload the next one
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
    );

    ad.show();
  }
}
