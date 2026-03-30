import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'ad_service.dart';

/// A self-managing banner ad widget.
///
/// Shows a banner ad when [AdService.shouldShowAds] is true.
/// Automatically loads and disposes the ad.
/// Renders [SizedBox.shrink] when ads should not be shown.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adService = context.read<AdService>();
    if (adService.shouldShowAds && _bannerAd == null) {
      _loadAd(adService);
    } else if (!adService.shouldShowAds && _bannerAd != null) {
      _disposeAd();
    }
  }

  void _loadAd(AdService adService) {
    _bannerAd = adService.createBannerAd(
      onLoaded: (_) {
        if (mounted) setState(() => _isLoaded = true);
      },
      onFailed: (_, __) {
        if (mounted) setState(() => _isLoaded = false);
        _bannerAd = null;
      },
    );
    _bannerAd!.load();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) setState(() => _isLoaded = false);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = context.watch<AdService>();
    if (!adService.shouldShowAds || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
