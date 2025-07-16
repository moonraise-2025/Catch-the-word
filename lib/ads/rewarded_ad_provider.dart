import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_info.dart';

class RewardedAdNotifier extends StateNotifier<RewardedAd?> {
  final Ref ref;
  final request = const AdRequest(); // Nên dùng const AdRequest()
  bool isCreating = false;

  RewardedAdNotifier(this.ref) : super(null) {
    createRewardedAd();
  }

  // Đổi tên tham số cho dễ hiểu: onUserEarnedRewardCallback và onAdDismissedCallback
  void showRewardedAd(Function onUserEarnedRewardCallback, Function onAdDismissedCallback) async {
    if (state == null) {
      print('Warning: attempt to show rewarded before loaded.');
      // Nếu không có quảng cáo, vẫn gọi onAdDismissedCallback để xử lý giao diện
      onAdDismissedCallback();
      return;
    }

    final ad = state;
    if (ad == null) {
      // Trường hợp này không nên xảy ra nếu state != null, nhưng là một check an toàn.
      onAdDismissedCallback();
      return;
    }

    // Set up callbacks before clearing state
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        print('ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        onAdDismissedCallback(); // <--- GỌI CALLBACK KHI QUẢNG CÁO ĐÓNG
        // Tạo quảng cáo mới sau một khoảng thời gian ngắn
        Future.delayed(const Duration(milliseconds: 500), () {
          createRewardedAd();
        });
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        onAdDismissedCallback(); // <--- GỌI CALLBACK KHI QUẢNG CÁO LỖI VÀ ĐÓNG
        // Tạo quảng cáo mới sau một khoảng thời gian ngắn
        Future.delayed(const Duration(milliseconds: 500), () {
          createRewardedAd();
        });
      },
    );

    try {
      // Xóa trạng thái quảng cáo để đảm bảo quảng cáo mới được tải
      state = null;
      ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedRewardCallback(); // <--- GỌI CALLBACK KHI NGƯỜI DÙNG NHẬN THƯỞNG
      });
    } catch (e) {
      print('Error showing rewarded ad: $e');
      onAdDismissedCallback(); // Gọi callback đóng nếu có lỗi khi cố gắng hiển thị
      createRewardedAd();
    }
  }

  void createRewardedAd() {
    if (isCreating || state != null) {
      print('Skipping createRewardedAd - Already loading or creating');
      return;
    }

    isCreating = true;

    RewardedAd.load(
        adUnitId: getRewardBasedVideoAdUnitId(),
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            state = ad;
            isCreating = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            state = null;
            isCreating = false;
            // Thêm độ trễ trước khi thử lại
            Future.delayed(const Duration(seconds: 1), () {
              if (state == null && !isCreating) {
                createRewardedAd();
              }
            });
          },
        ));
  }

  void disposeRewardedAd() {
    if (state != null) {
      state!.dispose();
      state = null;
    }
  }
}

final rewardedAdProvider = StateNotifierProvider<RewardedAdNotifier, RewardedAd?>((ref) {
  return RewardedAdNotifier(ref);
});