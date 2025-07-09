import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_info.dart';

class InterstitialAdNotifier extends StateNotifier<InterstitialAd?> {
  final Ref ref;
  final request = AdRequest();
  bool isCreating = false;

  InterstitialAdNotifier(this.ref) : super(null) {
    createInterstitialAd();
  }

  void showInterstitialAd(Function function) {
    if (state == null) {
      print('Warning: attempt to show interstitial before loaded.');
      function();
      return;
    }

    final ad = state;
    if (ad == null) {
      function();
      return;
    }

    // Set up callbacks before clearing state
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        print('ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        function();
        // Create new ad after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          createInterstitialAd();
        });
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        function();
        // Create new ad after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          createInterstitialAd();
        });
      },
    );

    try {
      // Clear state after setting up callbacks but before showing
      state = null;
      ad.show();
    } catch (e) {
      print('Error showing interstitial ad: $e');
      function();
      createInterstitialAd();
    }
  }

  void createInterstitialAd() {
    if (isCreating || state != null) {
      print('Skipping createInterstitialAd - Already loading or creating');
      return;
    }

    isCreating = true;

    InterstitialAd.load(
        adUnitId: getInterstitialAdUnitId(),
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            state = ad;
            isCreating = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            state = null;
            isCreating = false;
            // Add delay before retrying
            Future.delayed(Duration(seconds: 1), () {
              if (state == null && !isCreating) {
                createInterstitialAd();
              }
            });
          },
        ));
  }

  void disposeInterstitialAd() {
    if (state != null) {
      state!.dispose();
      state = null;
    }
  }
}

final interstitialAdProvider =
    StateNotifierProvider<InterstitialAdNotifier, InterstitialAd?>((ref) {
  return InterstitialAdNotifier(ref);
});
