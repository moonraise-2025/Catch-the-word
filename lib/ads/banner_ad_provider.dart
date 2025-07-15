import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_info.dart';

class BannerAdNotifier extends StateNotifier<BannerAd?> {
  final Ref ref;
  final request = AdRequest();

  BannerAdNotifier(this.ref) : super(null);

  Future<void> createAnchoredBanner(BuildContext context, {Function? function}) async {
    if (state != null) {
      print('Skipping createAnchoredBanner - Already loaded');
      return;
    }

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());

    if (size == null) {
      print('Unable to get adaptive banner size.');
      return;
    }

    final BannerAd banner = BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: size,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          state = ad as BannerAd?;
          if (function != null) {
            function();
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose();
          state = null;
        },
      ),
    );

    return banner.load();
  }

  void disposeBannerAd() {
    if (state != null) {
      state!.dispose();
      state = null;
    }
  }
}

final bannerAdProvider = StateNotifierProvider<BannerAdNotifier, BannerAd?>((ref) {
  return BannerAdNotifier(ref);
});

Widget getBanner(BuildContext context, WidgetRef ref) {
  final bannerAd = ref.watch(bannerAdProvider);
  if (bannerAd == null) {
    return Container();
  } else {
    return Container(
      height: bannerAd.size.height.toDouble(),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AdWidget(ad: bannerAd),
    );
  }
}
