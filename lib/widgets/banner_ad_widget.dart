import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retries = 0;
  static const _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _bannerAd?.dispose();
    _isLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: AdsService.instance.bannerAdUnitId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
          if (identical(_bannerAd, ad)) _bannerAd = null;
          if (mounted && _retries < _maxRetries) {
            _retries++;
            Future.delayed(Duration(seconds: 30 * _retries), () {
              if (mounted) _load();
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AdSize.banner.height.toDouble(),
      child: (_isLoaded && _bannerAd != null)
          ? AdWidget(ad: _bannerAd!)
          : const SizedBox.shrink(),
    );
  }
}
