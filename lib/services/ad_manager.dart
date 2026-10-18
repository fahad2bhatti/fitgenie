// lib/services/ad_manager.dart
//
// FitGenie ad layer: App Open, Rewarded (scan + chat),
// and a reusable banner widget for Progress / Calories / Library list.
//
// Setup: call `AdManager.instance.init()` AFTER MobileAds.instance.initialize()
// and after UMP consent is handled.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google ke official test IDs debug mode mein, release mein tumhare real IDs.
class AdIds {
  // TODO: AdMob console se naye units banake yahan paste karo.
  static const _appOpenRelease = 'ca-app-pub-8397637614188934/8832526681';
  static const _rewardedScanRelease = 'ca-app-pub-8397637614188934/1384272347';
  static const _rewardedChatRelease = 'ca-app-pub-8397637614188934/4837441355';
  static const _bannerScreensRelease = 'ca-app-pub-8397637614188934/4934389139';

  static String get appOpen =>
      kDebugMode ? 'ca-app-pub-3940256099942544/9257395921' : _appOpenRelease;
  static String get rewardedScan => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : _rewardedScanRelease;
  static String get rewardedChat => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : _rewardedChatRelease;
  static String get bannerScreens => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : _bannerScreensRelease;
}

enum RewardKind { scan, chat }

/// earned      -> user ne ad poora dekha, reward do
/// dismissed   -> user ne beech mein band kar diya, reward NAHI
/// unavailable -> ad load nahi hua (No fill etc.), fail-open: feature allow karo
enum RewardResult { earned, dismissed, unavailable }

class AdManager with WidgetsBindingObserver {
  AdManager._();
  static final AdManager instance = AdManager._();

  // ---- shared state ----
  bool _isShowingFullScreenAd = false;
  DateTime? _lastFullScreenEnd;
  DateTime? _suppressAppOpenUntil;
  bool _initialized = false;

  // ---- app open ----
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;
  DateTime? _lastAppOpenShown;
  bool _appOpenLoading = false;
  static const _appOpenMinGap = Duration(hours: 4);
  static const _appOpenMaxAge = Duration(hours: 4); // Google: 4h baad ad expire

  // ---- rewarded ----
  final Map<RewardKind, RewardedAd?> _rewarded = {};
  final Set<RewardKind> _rewardedLoading = {};

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _loadAppOpen();
    _loadRewarded(RewardKind.scan);
    _loadRewarded(RewardKind.chat);
  }

  /// Permission dialog (camera, notifications) app ko pause/resume karwata hai,
  /// jis se App Open ad galat jagah aa sakta hai. Permission maangne se pehle
  /// ye call karo.
  void suppressAppOpen([Duration d = const Duration(seconds: 8)]) {
    _suppressAppOpenUntil = DateTime.now().add(d);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAppOpenIfAvailable();
    }
  }

  void _markFullScreenEnded() {
    _isShowingFullScreenAd = false;
    _lastFullScreenEnd = DateTime.now();
  }

  // ======================= APP OPEN =======================

  void _loadAppOpen() {
    if (_appOpenLoading || _appOpenAd != null) return;
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (e) {
          _appOpenLoading = false;
          _appOpenAd = null;
          debugPrint('AppOpen load failed: ${e.code} ${e.message}');
        },
      ),
    );
  }

  bool get _appOpenFresh =>
      _appOpenAd != null &&
      _appOpenLoadedAt != null &&
      DateTime.now().difference(_appOpenLoadedAt!) < _appOpenMaxAge;

  /// Cold start (splash ke baad) aur resume dono jagah yehi call hoti hai.
  void showAppOpenIfAvailable() {
    final now = DateTime.now();

    if (_isShowingFullScreenAd) return;

    // Rewarded/interstitial band hone ke baad jo "resume" aata hai usay ignore karo.
    if (_lastFullScreenEnd != null &&
        now.difference(_lastFullScreenEnd!) < const Duration(seconds: 3)) {
      return;
    }
    if (_suppressAppOpenUntil != null && now.isBefore(_suppressAppOpenUntil!)) {
      return;
    }
    if (_lastAppOpenShown != null &&
        now.difference(_lastAppOpenShown!) < _appOpenMinGap) {
      return;
    }
    if (!_appOpenFresh) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _loadAppOpen();
      return;
    }

    final ad = _appOpenAd!;
    _appOpenAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowingFullScreenAd = true;
        _lastAppOpenShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _markFullScreenEnded();
        ad.dispose();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, e) {
        _markFullScreenEnded();
        ad.dispose();
        _loadAppOpen();
      },
    );
    ad.show();
  }

  // ======================= REWARDED =======================

  String _rewardedId(RewardKind k) =>
      k == RewardKind.scan ? AdIds.rewardedScan : AdIds.rewardedChat;

  void _loadRewarded(RewardKind k) {
    if (_rewardedLoading.contains(k) || _rewarded[k] != null) return;
    _rewardedLoading.add(k);
    RewardedAd.load(
      adUnitId: _rewardedId(k),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading.remove(k);
          _rewarded[k] = ad;
        },
        onAdFailedToLoad: (e) {
          _rewardedLoading.remove(k);
          _rewarded[k] = null;
          debugPrint('Rewarded($k) load failed: ${e.code} ${e.message}');
        },
      ),
    );
  }

  bool isRewardedReady(RewardKind k) {
    final ready = _rewarded[k] != null;
    if (!ready) _loadRewarded(k); // pichla load fail hua to dobara try
    return ready;
  }

  /// Usage:
  ///   final r = await AdManager.instance.showRewarded(RewardKind.scan);
  ///   if (r == RewardResult.dismissed) return;   // allow nahi
  ///   // earned ya unavailable -> aage badho
  Future<RewardResult> showRewarded(RewardKind k) async {
    final ad = _rewarded[k];
    if (ad == null) {
      _loadRewarded(k); // agli baar ke liye
      return RewardResult.unavailable;
    }
    _rewarded[k] = null;

    final completer = Completer<RewardResult>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _isShowingFullScreenAd = true,
      onAdDismissedFullScreenContent: (shown) {
        _markFullScreenEnded();
        shown.dispose();
        _loadRewarded(k);
        if (!completer.isCompleted) {
          completer
              .complete(earned ? RewardResult.earned : RewardResult.dismissed);
        }
      },
      onAdFailedToShowFullScreenContent: (shown, e) {
        _markFullScreenEnded();
        shown.dispose();
        _loadRewarded(k);
        if (!completer.isCompleted)
          completer.complete(RewardResult.unavailable);
      },
    );

    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  // ======================= EXTERNAL FULL-SCREEN HOOKS =======================

  /// AdsService ka interstitial dikhne / band hone par call hota hai, taake
  /// App Open ad uske baad wale "resume" par na aaye.
  void fullScreenStarted() => _isShowingFullScreenAd = true;
  void fullScreenEnded() => _markFullScreenEnded();
}

// ======================= BANNER WIDGET =======================

/// Sirf: Dashboard, Progress, Calories, Library list.
/// Usage: Scaffold(bottomNavigationBar: SafeArea(child: ScreenBannerAd()), ...)
/// Load na ho to koi jagah nahi gheerta (SizedBox.shrink).
class ScreenBannerAd extends StatefulWidget {
  const ScreenBannerAd({super.key});

  @override
  State<ScreenBannerAd> createState() => _ScreenBannerAdState();
}

class _ScreenBannerAdState extends State<ScreenBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: AdIds.bannerScreens,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          debugPrint('Banner load failed: ${e.code} ${e.message}');
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
