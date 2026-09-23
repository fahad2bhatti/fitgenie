import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static Future<void> initialize() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters(tagForUnderAgeOfConsent: false);

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (!completer.isCompleted) completer.complete();
          });
        } else {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint('UMP consent error: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
    await MobileAds.instance.initialize();
  }

  bool get _testMode => kDebugMode;

  String get bannerAdUnitId => _testMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-8397637614188934/1553968781';

  Future<AdSize?> adaptiveBannerSize(double width) async =>
      await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width.toInt());

  BannerAd createBannerAd({
    required AdSize size,
    required void Function(Ad ad) onLoaded,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  String get interstitialAdUnitId => _testMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-8397637614188934/7199855166';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime _lastInterstitialShown = DateTime.fromMillisecondsSinceEpoch(0);
  int _interstitialShownThisSession = 0;

  static const _minGapBetweenInterstitials = Duration(minutes: 2);
  static const _maxInterstitialsPerSession = 3;

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
          debugPrint('Interstitial failed: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  void showInterstitialAd({void Function()? onDismissed}) {
    final now = DateTime.now();
    final capped =
        now.difference(_lastInterstitialShown) < _minGapBetweenInterstitials ||
            _interstitialShownThisSession >= _maxInterstitialsPerSession;

    final ad = _interstitialAd;
    if (ad == null || capped) {
      onDismissed?.call();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
    );

    _lastInterstitialShown = now;
    _interstitialShownThisSession++;
    ad.show();
  }

  String get rewardedAdUnitId => _testMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-8397637614188934/REPLACE_ME';

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  void loadRewardedAd() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required void Function() onRewardEarned,
    void Function()? onDismissed,
  }) {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      onDismissed?.call();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onDismissed?.call();
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      onRewardEarned();
    });
  }

  String get appOpenAdUnitId => _testMode
      ? 'ca-app-pub-3940256099942544/9257395921'
      : 'ca-app-pub-8397637614188934/REPLACE_ME';

  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;
  static const _appOpenExpiry = Duration(hours: 4);

  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpen failed: $error');
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    final ad = _appOpenAd;
    if (ad == null || _appOpenLoadedAt == null) {
      loadAppOpenAd();
      return;
    }
    if (DateTime.now().difference(_appOpenLoadedAt!) > _appOpenExpiry) {
      ad.dispose();
      _appOpenAd = null;
      loadAppOpenAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    ad.show();
  }
}
