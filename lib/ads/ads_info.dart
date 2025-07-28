import 'package:flutter/foundation.dart';

bool get isDebugMode {
  if (kDebugMode) {
    return true;
  }
  return false;
}

// String getInterstitialAdUnitId() {
//   if (isDebugMode) {
//     return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial ad unit ID
//   }
//   return 'ca-app-pub-YOUR_NEW_APP_ID/YOUR_NEW_BANNER_AD_UNIT_ID'; // Your production interstitial ad unit ID
// }
//
String getRewardBasedVideoAdUnitId() {
  if (isDebugMode) {
    return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded ad unit ID
  }
  return 'ca-app-pub-4955170106426992/3119524255'; // Production rewarded ad unit ID
}

String getBannerAdUnitId() {
  if (isDebugMode) {
    return 'ca-app-pub-3940256099942544/6300978111'; // Test banner ad unit ID
  }
  return 'ca-app-pub-4955170106426992/3067553363'; // Production banner ad unit ID
}

