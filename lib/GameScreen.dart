import 'package:duoihinhbatchu/ads/rewarded_ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'PopupAnswerCorrect.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:duoihinhbatchu/GiftPopup.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'audio_manager.dart';

import 'package:duoihinhbatchu/model/question.dart';
import 'package:duoihinhbatchu/service/question_service.dart';

import 'firebase_analysis/analytics_service.dart';


class GameScreen extends ConsumerStatefulWidget {

  final int initialLevel;

  const GameScreen({super.key, this.initialLevel = 1});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState(); // Thay đổi ở đây
}

class _GameScreenState extends ConsumerState<GameScreen> with TickerProviderStateMixin {

  List<Question> questions = [];
  bool _isLoadingQuestions = true;
  Map<String, bool> _isPressedMap = {};

  bool _adRewardEarned = false; //ads

  int dailyCount = 0;
  int daily30Count = 0;
  int daily50Count = 0;

  int currentQuestion = 0;
  int level = 1;
  int diamonds = 0;

  late List<String> answerSlots;
  late List<String> charOptions;
  late List<int?> answerCharIndexes;
  late List<bool> charUsed;
  int currentSlot = 0;
  bool isCorrect = false;

  Timer? _hintTimer;
  int _hintSeconds = 30;
  bool _hintActive = false;
  bool _hintUsedOnce = false;
  String? _hintBanner;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool isWrong = false;
  late int maxAnswerLength;
  late double bannerHeight;

  final GlobalKey previewContainerKey = GlobalKey();
  // int dummyState = 0; // Biến này không được sử dụng

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  void _preloadNextImage(int questionIndex) {
    if (questionIndex < questions.length) {
      final nextQuestion = questions[questionIndex];
      final imageProvider = NetworkImage(nextQuestion.imgQuestion);
      // precacheImage yêu cầu context, nên đảm bảo nó có sẵn
      precacheImage(imageProvider, context);
      debugPrint('Đã tải trước ảnh cho câu hỏi ${nextQuestion.id}');
    }
  }

  Future<void> captureAndShareWidget() async {
    try {
      // Đợi một chút để đảm bảo UI đã render xong
      await Future.delayed(const Duration(milliseconds: 100));

      final RenderObject? renderObject = previewContainerKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        debugPrint('Không tìm thấy RenderObject');
        return;
      }

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('RenderObject không phải là RenderRepaintBoundary');
        return;
      }

      final RenderRepaintBoundary boundary = renderObject;

      // Đợi để đảm bảo widget đã được vẽ xong
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 0));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('Không thể tạo byte data từ image');
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Tạo file tạm
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/dhbc_screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // Chia sẻ file
      await Share.shareFiles(
        [file.path],
        text: 'Hình gì đây? 🎮\nTải app tại: https://play.google.com/store/apps/details?id=com.duoihinhbatchu.app',
      );

      debugPrint('Chia sẻ thành công: ${file.path}');
    } catch (e) {
      debugPrint('Lỗi chụp/chia sẻ widget: $e');
      // Hiển thị thông báo lỗi cho user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chia sẻ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService().logLevelScreen(widget.initialLevel);
    _loadAllDataAndInitGame(); // Gọi hàm tải dữ liệu và khởi tạo game
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shakeAnimation =
        Tween<double>(begin: 0, end: 6 * 2 * 3.1415926535).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.linear),
        );
    _initAnimations();
    checkAndResetDailyProgress();
    _loadDiamonds();
    _loadRewardedAd();

    // Khởi tạo BannerAd
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-4955170106426992/3758722469', // Test banner ad unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isBannerAdReady = false;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _controller.dispose();
    _shakeController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }
  void _goToNextQuestion() {
    setState(() {
      level++;
      currentQuestion++;
      isCorrect = false;
      isWrong = false;
      _hintUsedOnce = false;
    });

    if (currentQuestion < questions.length) {
      _initGame();
      _preloadNextImage(currentQuestion + 1);
    }
    _saveGameProgress();
  }

  void _initGame() {
    if (questions.isEmpty) {
      debugPrint("Lỗi: Không có câu hỏi để khởi tạo game.");
      return;
    }

    final answer = questions[currentQuestion].answer.toUpperCase();
    answerSlots = List.filled(answer.replaceAll(' ', '').length, '');
    answerCharIndexes = List.filled(
        answer.replaceAll(' ', '').length, null);
    charOptions = _generateCharOptions(
        answer.replaceAll(' ', ''));

    charUsed = List.filled(charOptions.length, false);
    currentSlot = 0;
    isCorrect = false;
    _controller.reset();
    _controller.forward();
    _hintBanner = null;
    _hintUsedOnce = false;
    // _hintWordIndex = 0; // Đã bỏ
    _startHintCountdown();
  }

  List<String> _generateCharOptions(String answer) {
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    List<String> chars = answer.split('');
    Random rnd = Random();
    int numDistractors;
    if (answer.length <= 5) {
      numDistractors = 5 + rnd.nextInt(6);
    } else if (answer.length <= 10) {
      numDistractors = 4 + rnd.nextInt(2);
    } else {
      if (answer.length < 16) {
        numDistractors = 16 - answer.length;
      } else {
        numDistractors = 1 + rnd.nextInt(2);
      }
    }
    // Thêm các ký tự gây nhiễu, đảm bảo không trùng với ký tự trong đáp án chính
    // và đủ số lượng theo logic đã có
    while (chars.length < answer.length + numDistractors) {
      String c = alphabet[rnd.nextInt(alphabet.length)];
      if (!answer.contains(c)) { // Chỉ thêm nếu ký tự không có trong đáp án
        chars.add(c);
      }
      // Nếu có quá nhiều ký tự và không thể tìm thấy ký tự gây nhiễu mới, vòng lặp có thể bị treo.
      // Cần có một cơ chế thoát hoặc giới hạn số lần thử.
      // Hiện tại, với alphabet 26 chữ cái, và answer chỉ vài chữ, khả năng treo rất thấp.
      if (chars.length >= alphabet.length) { // Bảo vệ khỏi vòng lặp vô hạn nếu answer quá dài
        break;
      }
    }
    chars.shuffle();
    return chars;
  }

  void _onCharTap(int idx) async {
    int targetSlot = answerSlots.indexOf('');
    if (targetSlot == -1) {
      return;
    }
    if (charUsed[idx]) {
      return;
    }

    setState(() {
      answerSlots[targetSlot] = charOptions[idx];
      answerCharIndexes[targetSlot] = idx;
      charUsed[idx] = true;
      currentSlot = answerSlots.indexOf('');
      if (currentSlot == -1) {
        currentSlot = answerSlots.length;
      }
    });

    if (currentSlot == answerSlots.length) {

      final userAnswer = answerSlots.join('');
      final correctAnswer = questions[currentQuestion]
          .answer
          .toUpperCase()
          .replaceAll(' ', '');

      final correct = userAnswer == correctAnswer;

      setState(() {
        isCorrect = correct;
      });

      if (correct) {
        // Bắt đầu animation rung lặp lại
        _shakeController.repeat();

        await Future.delayed(const Duration(seconds: 2));

        // Dừng animation rung sau khi hết thời gian
        _shakeController.stop();
        // Đảm bảo animation trở về trạng thái ban đầu sau khi dừng
        _shakeController.value = 0.0; // Đặt lại về 0 để không có độ xoay dư thừa

        showCorrectDialog();

        if (dailyCount < 1) dailyCount++;
        if (daily30Count < 30) daily30Count++;
        if (daily50Count < 50) daily50Count++;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('dailyCount', dailyCount);
        await prefs.setInt('daily30Count', daily30Count);
        await prefs.setInt('daily50Count', daily50Count);
      } else {
        setState(() {
          isWrong = true;
        });

        // Bắt đầu animation rung lặp lại cho trường hợp sai
        _shakeController.repeat(); // Hoặc _shakeController.repeat(reverse: true);

        Future.delayed(const Duration(seconds: 2), () { // Thời gian bạn muốn chữ rung khi sai
          _shakeController.stop();
          _shakeController.value = 0.0; // Đặt lại về 0
          setState(() {
            isWrong = false;
            final answer = questions[currentQuestion].answer.toUpperCase();
            answerSlots = List.filled(answer.replaceAll(' ', '').length, '');
            answerCharIndexes =
                List.filled(answer.replaceAll(' ', '').length, null);
            charOptions = _generateCharOptions(answer.replaceAll(' ', ''));
            charUsed = List.filled(charOptions.length, false);
            currentSlot = 0;
            isCorrect = false;
          });
        });
      }
    }
    debugPrint(
        'Sau khi chọn: answerSlots = $answerSlots, charUsed = $charUsed, currentSlot = $currentSlot');
  }

  void _startHintCountdown() {
    setState(() {
      _hintSeconds = 30;
      _hintActive = true;
    });

    _hintTimer?.cancel();
    _hintTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hintSeconds == 0) {
        timer.cancel();
        setState(() => _hintActive = false);
      } else {
        setState(() => _hintSeconds--);
      }
    });
  }


  void _onAnswerSlotTap(int slotIndex) {
    if (answerCharIndexes[slotIndex] != null) {
      setState(() {
        int? charIdxToReturn = answerCharIndexes[slotIndex];
        if (charIdxToReturn != null && charIdxToReturn != -1) {
          charUsed[charIdxToReturn] = false;
        }
        answerSlots[slotIndex] = '';
        answerCharIndexes[slotIndex] = null;
        isCorrect = false;

        currentSlot = answerSlots.indexOf('');
        if (currentSlot == -1) {
          currentSlot = answerSlots.length;
        }

        debugPrint(
            'Sau khi xóa: answerSlots = $answerSlots, charUsed = $charUsed, currentSlot = $currentSlot');
      });
    }
  }

  void showCorrectDialog() {
    AudioManager().playNextLevelSound();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'InfoPopup',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PopupAnswerCorrect(
          onNext: () async {
            Navigator.of(context).pop();
            setState(() { // setState không cần async
              if (currentQuestion < questions.length - 1) {
                currentQuestion++;
                level++;
                diamonds += 5;
                AnalyticsService().logLevelScreen(level);
              } else {
                currentQuestion = 0;
                level = 1;
                diamonds = 0;
                AnalyticsService().logLevelScreen(level);
              }
              _initGame(); // Gọi _initGame sau khi cập nhật level/question
              _preloadNextImage(currentQuestion + 1);
              _saveGameProgress(); // Lưu trạng thái game
              _saveDiamonds(); // Lưu kim cương
            });
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {

        final opacityTween = TweenSequence<double>([
          TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 0.7),
          TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 0.3),
        ]);

        final scaleTween = TweenSequence<double>([
          TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.05), weight: 0.7),
          TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 0.3),
        ]);

        return ScaleTransition(
          scale: scaleTween.animate(animation),
          child: FadeTransition(
            opacity: opacityTween.animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> checkAndResetDailyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final lastDate = prefs.getString('lastRewardDate') ?? '';
    if (lastDate != todayStr) {
      await prefs.setInt('dailyCount', 0);
      await prefs.setInt('daily30Count', 0);
      await prefs.setInt('daily50Count', 0);
      await prefs.setBool('dailyRewarded', false);
      await prefs.setBool('daily30Rewarded', false);
      await prefs.setBool('daily50Rewarded', false);
      await prefs.setString('lastRewardDate', todayStr);
    }

    dailyCount = prefs.getInt('dailyCount') ?? 0;
    daily30Count = prefs.getInt('daily30Count') ?? 0;
    daily50Count = prefs.getInt('daily50Count') ?? 0;
  }

  void _showRevealLetterDialog() async {
    if (diamonds < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không đủ kim cương!',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      diamonds -= 10;
    });
    await _saveDiamonds();

    setState(() {
      final answer = questions[currentQuestion].answer.toUpperCase();
      bool allSlotsFilled = true; // Thêm biến cờ để kiểm tra
      for (int i = 0; i < answerSlots.length; i++) {
        if (answerSlots[i].isEmpty) {
          String correctChar =
          answer.replaceAll(' ', '')[i];
          for (int j = 0; j < charOptions.length; j++) {
            if (charOptions[j] == correctChar && !charUsed[j]) {
              answerSlots[i] = correctChar;
              answerCharIndexes[i] = j; // Cập nhật answerCharIndexes
              charUsed[j] = true;
              currentSlot = i + 1;
              break;
            }
          }
          allSlotsFilled = false; // Đánh dấu là chưa điền hết
          break; // Chỉ điền 1 chữ mỗi lần
        }
      }

      // Kiểm tra nếu tất cả các ô đã được điền (có thể do đã điền hết hoặc do chỉ còn 1 ô cuối cùng được điền)
      // và sau đó kiểm tra tính đúng đắn và kích hoạt hành động khi đúng.
      if (allSlotsFilled || answerSlots.every((slot) => slot.isNotEmpty)) {
        final userAnswer = answerSlots.join('');
        final correctAnswer = questions[currentQuestion].answer.toUpperCase().replaceAll(' ', '');

        if (userAnswer == correctAnswer) {
          isCorrect = true;
          _shakeController.repeat();
          Future.delayed(const Duration(seconds: 2), () {
            _shakeController.stop();
            _shakeController.value = 0.0;
            showCorrectDialog();

            if (dailyCount < 1) dailyCount++;
            if (daily30Count < 30) daily30Count++;
            if (daily50Count < 50) daily50Count++;
            SharedPreferences.getInstance().then((prefs) {
              prefs.setInt('dailyCount', dailyCount);
              prefs.setInt('daily30Count', daily30Count);
              prefs.setInt('daily50Count', daily50Count);
            });
          });
        }
      }
    });
  }


  void _onHint() {
    if (_hintActive) return;

    // Giả sử mô hình Question của bạn hiện có thuộc tính 'answerType'
    // và nó được điền từ dữ liệu JSON của bạn.
    final String? hintText = questions[currentQuestion].answerType;

    if (hintText != null && hintText.isNotEmpty) {
      setState(() {
        _hintBanner = hintText;
        _hintUsedOnce = true;
      });
    } else {
      // Dự phòng nếu answerType không khả dụng hoặc trống
      final answer = questions[currentQuestion].answer.toUpperCase();
      final words = answer.split(' ');
      String hint = words[0];
      setState(() {
        _hintBanner = hint;
        _hintUsedOnce = true;
      });
    }
  }

  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastLevel', level); // Lưu level hiện tại
  }

  Future<void> _saveDiamonds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('diamonds', diamonds);
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-4955170106426992/8920777166', // Test rewarded ad unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            print('DEBUG: Rewarded Ad loaded successfully.'); // Thêm log
          });
        },
        onAdFailedToLoad: (error) {
          setState(() {
            _isRewardedAdReady = false;
            _rewardedAd = null; // Đặt lại ad về null khi lỗi
          });
          print('DEBUG: Rewarded Ad failed to load: $error'); // Thêm log lỗi chi tiết
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải quảng cáo: ${error.code} - ${error.message}'), // Hiển thị lỗi chi tiết hơn
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void _showRewardedAd({required VoidCallback onReward}) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('DEBUG: Ad showed full screen content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('DEBUG: Ad dismissed. Checking if reward earned...');
          ad.dispose(); // Giải phóng quảng cáo sau khi đóng
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          // Kiểm tra xem thưởng đã được nhận chưa trước khi thực hiện logic
          if (_adRewardEarned) {
            print('DEBUG: Reward was earned. Proceeding with game logic.');
            onReward(); // Thực hiện logic nhận thưởng
          } else {
            print('DEBUG: Ad dismissed, but no reward was earned.');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn chưa nhận được thưởng. Vui lòng xem hết quảng cáo.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          _loadRewardedAd(); // Tải lại quảng cáo cho lần sau
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('DEBUG: Ad failed to show full screen content: $error');
          ad.dispose(); // Giải phóng quảng cáo khi lỗi hiển thị
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể hiển thị quảng cáo: ${error.code} - ${error.message}'),
              duration: const Duration(seconds: 3),
            ),
          );
          _loadRewardedAd(); // Tải lại quảng cáo cho lần sau
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _adRewardEarned = true;
          print('DEBUG: User earned reward!');
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quảng cáo chưa sẵn sàng. Đang thử tải lại...')),
      );
      _loadRewardedAd(); // Thử tải lại ngay lập tức nếu chưa sẵn sàng
    }
  }

  void _onSkipLevel() {
    final rewardedAdNotifier = ref.read(rewardedAdProvider.notifier);
    final rewardedAd = ref.read(rewardedAdProvider);

    if (rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có quảng cáo nào sẵn sàng. Vui lòng thử lại sau 5s.'),
          duration: Duration(seconds: 2),
        ),
      );
      rewardedAdNotifier.createRewardedAd();
      return;
    }

    _adRewardEarned = false;

    rewardedAdNotifier.showRewardedAd(
          () {
        // onUserEarnedReward callback
        _adRewardEarned = true;
        print('DEBUG: Người dùng đã nhận thưởng.');
      },
          () {
        // onAdDismissedFullScreenContent callback
        print('DEBUG: Quảng cáo đã đóng. Đang kiểm tra xem thưởng đã nhận chưa...');
        if (_adRewardEarned) {
          print('DEBUG: Thưởng đã được nhận. Tiến hành logic hiện đáp án.');
          final correctAnswer = questions[currentQuestion]
              .answer
              .toUpperCase()
              .replaceAll(' ', '');

          setState(() {
            answerSlots = correctAnswer.split('');
            isCorrect = true; // Đặt isCorrect thành true
            charUsed = List.filled(charOptions.length, false);
            for (int i = 0; i < correctAnswer.length; i++) {
              final char = correctAnswer[i];
              for (int j = 0; j < charOptions.length; j++) {
                if (charOptions[j] == char && !charUsed[j]) {
                  charUsed[j] = true;
                  break;
                }
              }
            }
          });

          // Chỉ cần gọi showCorrectDialog(), nó sẽ xử lý animation rung
          // sau khi đáp án đã được hiển thị trên UI.
          Future.delayed(const Duration(milliseconds: 500), () { // Có thể giảm thời gian chờ nếu muốn
            if (mounted) {
              // isCorrect vẫn là true, không cần đặt lại thành false ở đây.
              // showCorrectDialog sẽ tự quản lý trạng thái rung và reset.
              showCorrectDialog();
            }
          });
        } else {
          print('DEBUG: Quảng cáo đã đóng, nhưng thưởng CHƯA được nhận. Không hiện đáp án.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (_isLoadingQuestions) {
    //   return const Scaffold(
    //     backgroundColor: Colors.black,
    //     body: Center(
    //       child: CircularProgressIndicator(
    //         color: Colors.white,
    //       ),
    //     ),
    //   );
    // }
    if (_isLoadingQuestions) {

      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SizedBox.shrink(),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Không thể tải câu hỏi. Vui lòng kiểm tra file JSON hoặc đường dẫn.",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Quay lại màn hình trước
                },
                child: const Text("Quay lại"),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // final double imageContainerSize = screenWidth * 0.7; // This variable is not used
    bannerHeight = screenHeight * 0.045;
    final double smallPadding = screenWidth * 0.025;
    final double mediumPadding = screenWidth * 0.05;

    const int maxPerRow = 7;
    final answer = questions[currentQuestion].answer.toUpperCase();
    final double adjustedSize =
        (screenWidth - 2 * mediumPadding - (maxPerRow + 1) * 4.0) /
            maxPerRow *
            0.8;

    return RepaintBoundary(
      key: previewContainerKey,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BackgroundGame.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children:[
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: mediumPadding, vertical: smallPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _saveGameProgress();
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          'assets/images/home.png',
                          width: screenWidth * 0.07,
                          height: screenWidth * 0.07,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Level ',
                              style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('$level',
                              style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$diamonds',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              SizedBox(width: screenWidth * 0.0015),
                              Image.asset(
                                'assets/images/Diamond_Borderless.png',
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          SizedBox(width: smallPadding),
                          GestureDetector(
                            onTap: () {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: 'Giftpopup',
                                barrierColor: Colors.black.withOpacity(0.5),
                                transitionDuration: const Duration(milliseconds: 300),
                                pageBuilder: (context, animation, secondaryAnimation) {
                                  return  Giftpopup(
                                    dailyCount: dailyCount,
                                    daily30Count: daily30Count,
                                    daily50Count: daily50Count,
                                    onReward: (amount) async {
                                      setState(() {
                                        diamonds += amount;
                                      });
                                      final prefs =
                                      await SharedPreferences.getInstance();
                                      await prefs.setInt('diamonds', diamonds);
                                    },
                                  );
                                },
                                transitionBuilder: (context, animation, secondaryAnimation, child) {

                                  final opacityTween = TweenSequence<double>([
                                    TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 0.7),
                                    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 0.3),
                                  ]);

                                  final scaleTween = TweenSequence<double>([
                                    TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.05), weight: 0.7),
                                    TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 0.3),
                                  ]);

                                  return ScaleTransition(
                                    scale: scaleTween.animate(animation),
                                    child: FadeTransition(
                                      opacity: opacityTween.animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                              );
                            },
                            child: Image.asset(
                              'assets/images/gift.png',
                              width: screenWidth * 0.07,
                              height: screenWidth * 0.07,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.001),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.005),
                      // Ảnh câu hỏi
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.2),
                        width: double.infinity,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double imageBoxSize = constraints.maxWidth;
                                return Container(
                                  width: imageBoxSize,
                                  height: imageBoxSize * 0.95,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black26),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      questions[currentQuestion].imgQuestion,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error,
                                                  color: Colors.red, size: 40),
                                              SizedBox(height: 8), // Add some spacing between the icon and text
                                              Text(
                                                "ảnh chưa được tải lên",
                                                style: TextStyle(color: Colors.red, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),


                      // Spacer để đẩy text gợi ý xuống giữa
                      // Expanded(
                      //   child: (_hintBanner != null)
                      //       ? Center(
                      //     child: Text(
                      //       _hintBanner!,
                      //       textAlign: TextAlign.center,
                      //       style: TextStyle(
                      //         fontSize: screenWidth * 0.05,
                      //         color: Colors.deepPurple,
                      //       ),
                      //     ),
                      //   )
                      //       : const SizedBox.shrink(),
                      // ),

                    ],
                  ),

                ),
                // Hiển thị text gợi ý căn giữa nếu có gợi ý
                // if (_hintBanner != null)
                //   Padding(
                //     padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                //     child: Center(
                //       child: Text(
                //         _hintBanner!,
                //         textAlign: TextAlign.center,
                //         style: TextStyle(
                //           fontSize: screenWidth * 0.07,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.deepPurple,
                //         ),
                //       ),
                //     ),
                //   ),
                SizedBox(height: screenHeight * 0.01),


                Expanded(
                  flex: 2, // Cân đối flex để phần này chiếm ít không gian hơn ảnh
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung trong phần này
                    children: [
                      // Khoảng cách giữa ảnh và đáp án
                      SizedBox(height: screenHeight * 0.01),
                      // Đáp án
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: mediumPadding),
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildAnswerRows(
                            answerSlots,
                            questions[currentQuestion].answer,
                            adjustedSize,
                          ),
                        ),
                      ),
                      // Khoảng cách giữa đáp án và chữ cái lựa chọn
                      SizedBox(height: screenHeight * 0.01),
                      // Các chữ cái lựa chọn
                      Column(
                        children: buildCharRows(adjustedSize * 1.2),
                      ),
                    ],
                  ),
                ),

                // Hàng các nút chức năng
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  child: Column(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.07,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Nút "Hiện Đáp Án"
                            AnimatedScale(
                              scale: _isPressedMap['reveal_answer_button'] ?? false ? 0.90 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTapDown: (_) {
                                  setState(() => _isPressedMap['reveal_answer_button'] = true);
                                  Future.delayed(const Duration(milliseconds: 150), () {
                                    if (mounted) {
                                      setState(() => _isPressedMap['reveal_answer_button'] = false);
                                    }
                                  });
                                },
                                onTapUp: (_) {},
                                onTapCancel: () => setState(() => _isPressedMap['reveal_answer_button'] = false),
                                child: SizedBox(
                                  width: screenWidth * 0.3,
                                  child: ElevatedButton(
                                    onPressed: _showRevealLetterDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF90C240),
                                      disabledBackgroundColor: const Color(0xFF90C240).withOpacity(0.6),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Hiện Đáp Án',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.030,
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '10 ',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.025, // Giữ nguyên kích thước chữ
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.middle,
                                                child: Image.asset(
                                                  'assets/images/Diamond_Borderless.png',
                                                  width: screenWidth * 0.03, // Giữ nguyên kích thước biểu tượng
                                                  height: screenWidth * 0.03, // Giữ nguyên kích thước biểu tượng
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Nút "Hỏi Bạn"
                            AnimatedScale(
                              scale: _isPressedMap['ask_friend_button'] ?? false ? 0.90 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTapDown: (_) {
                                  setState(() => _isPressedMap['ask_friend_button'] = true);
                                  Future.delayed(const Duration(milliseconds: 150), () {
                                    if (mounted) {
                                      setState(() => _isPressedMap['ask_friend_button'] = false);
                                    }
                                  });
                                },
                                onTapUp: (_) {},
                                onTapCancel: () => setState(() => _isPressedMap['ask_friend_button'] = false),
                                child: SizedBox(
                                  width: screenWidth * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      debugPrint('Nút Hỏi Bạn được bấm');
                                      captureAndShareWidget();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF8B52E),
                                      disabledBackgroundColor: const Color(0xFFF8B52E).withOpacity(0.6),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Hỏi Bạn',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.030,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Nút "Gợi Ý"
                            // AnimatedScale(
                            //   scale: _isPressedMap['hint_button'] ?? false ? 0.90 : 1.0,
                            //   duration: const Duration(milliseconds: 300),
                            //   child: GestureDetector(
                            //     onTapDown: (_) {
                            //       setState(() => _isPressedMap['hint_button'] = true);
                            //       Future.delayed(const Duration(milliseconds: 150), () {
                            //         if (mounted) {
                            //           setState(() => _isPressedMap['hint_button'] = false);
                            //         }
                            //       });
                            //     },
                            //     onTapUp: (_) {},
                            //     onTapCancel: () => setState(() => _isPressedMap['hint_button'] = false),
                            //     child: SizedBox(
                            //       width: screenWidth * 0.23,
                            //       child: ElevatedButton(
                            //         onPressed: (_hintActive || _hintUsedOnce) ? null : () => _onHint(),
                            //         style: ElevatedButton.styleFrom(
                            //           backgroundColor: const Color(0xFFF3A3C5),
                            //           disabledBackgroundColor: const Color(0xFFF3A3C5).withOpacity(0.6),
                            //           padding: EdgeInsets.zero,
                            //           shape: RoundedRectangleBorder(
                            //             borderRadius: BorderRadius.circular(10),
                            //           ),
                            //         ),
                            //         child: Column(
                            //           mainAxisSize: MainAxisSize.min,
                            //           children: [
                            //             Text(
                            //               'Gợi Ý',
                            //               style: TextStyle(
                            //                 fontWeight: FontWeight.bold,
                            //                 color: (_hintActive || _hintUsedOnce)
                            //                     ? Colors.white70
                            //                     : Colors.white,
                            //                 fontSize: screenWidth * 0.030,
                            //               ),
                            //             ),
                            //             if (_hintActive)
                            //               Text(
                            //                 '${_hintSeconds}s',
                            //                 style: TextStyle(
                            //                   color: Colors.white70,
                            //                   fontSize: screenWidth * 0.025,
                            //                 ),
                            //               ),
                            //           ],
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),

                            // Nút "Qua Màn"
                            AnimatedScale(
                              scale: _isPressedMap['pass_level_button'] ?? false ? 0.90 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTapDown: (_) {
                                  setState(() => _isPressedMap['pass_level_button'] = true);
                                  Future.delayed(const Duration(milliseconds: 150), () {
                                    if (mounted) {
                                      setState(() => _isPressedMap['pass_level_button'] = false);
                                    }
                                  });
                                },
                                onTapUp: (_) {},
                                onTapCancel: () => setState(() => _isPressedMap['pass_level_button'] = false),
                                child: SizedBox(
                                  width: screenWidth * 0.30,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      print('Nút QUA MÀN đã được bấm');
                                      _showRewardedAd(
                                          onReward: () {
                                            print('Người dùng đã nhận thưởng!');
                                            // Điền đáp án đúng lên màn hình
                                            final correctAnswer = questions[currentQuestion].answer.toUpperCase().replaceAll(' ', '');
                                            setState(() {
                                              answerSlots = correctAnswer.split('');
                                              isCorrect = true;
                                              charUsed = List.filled(charOptions.length, false);
                                              for (int i = 0; i < correctAnswer.length; i++) {
                                                final char = correctAnswer[i];
                                                for (int j = 0; j < charOptions.length; j++) {
                                                  if (charOptions[j] == char && !charUsed[j]) {
                                                    charUsed[j] = true;
                                                    break;
                                                  }
                                                }
                                              }
                                            });

                                            // Hiện popup correct answer sau khi đã điền đáp án
                                            _shakeController.forward(from: 0);

                                            Future.delayed(const Duration(seconds: 1), () {
                                              if (mounted) {
                                                setState(() {
                                                  isCorrect = false;
                                                });
                                                showCorrectDialog();
                                              }
                                            });
                                          }
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "QUA MÀN",
                                          style: TextStyle(
                                            color: const Color(0xFF616FD3),
                                            fontSize: screenWidth * 0.030,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "(QC 15s~30s)",
                                          style: TextStyle(
                                            color: const Color(0xFF43ADED),
                                            fontSize: screenWidth * 0.025, // Giữ nguyên kích thước chữ
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: getBanner(context, ref), // Banner quảng cáo nếu có
                ),
              ], // <-- THÊM DẤU ĐÓNG ']' Ở ĐÂY
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> buildCharRows(double size) {
    const int maxPerRow = 7;
    List<Widget> rows = [];
    int total = charOptions.length;
    int idx = 0;

    while (idx < total) {
      int count = (total - idx) >= maxPerRow ? maxPerRow : (total - idx);
      List<Widget> row = [];

      for (int i = 0; i < count; i++) {
        int charIdx = idx + i;
        row.add(
          SizedBox(
            width: size,
            height: size,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: charUsed[charIdx]
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : GestureDetector(
                key: ValueKey('char_$charIdx'),
                onTap: () => _onCharTap(charIdx),
                child: Container(
                  margin: EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      charOptions[charIdx],
                      style: TextStyle(
                        fontSize: size * 0.45,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF556B2F),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row,
      ));
      if (idx + count < total) {
        rows.add(SizedBox(height: size * 0.05));
      }
      idx += count;
    }

    return rows;
  }

  List<Widget> _buildAnswerRows(
      List<String> slots, String answer, double size) {
    List<Widget> rows = [];
    int slotIdx = 0;
    final words = answer.split(' ');
    const int maxCharsPerRow = 7;

    // Nếu chỉ có đúng 2 từ, luôn hiển thị mỗi từ trên 1 dòng, căn giữa từng dòng
    if (words.length == 2) {
      int maxLen = words[0].length > words[1].length ? words[0].length : words[1].length;
      for (int i = 0; i < 2; i++) {
        List<Widget> row = [];
        for (int j = 0; j < words[i].length; j++) {
          row.add(_buildAnswerBox(slotIdx++, slots, size));
          if (j < words[i].length - 1) {
            row.add(SizedBox(width: size * 0.1));
          }
        }
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row,
        ));
        if (i == 0) {
          rows.add(SizedBox(height: size * 0.1));
        }
      }
      return rows;
    }

    // Gom nhóm các từ thành từng hàng
    List<List<String>> groupedWords = [];
    List<String> currentGroup = [];
    int currentLen = 0;
    for (int i = 0; i < words.length; i++) {
      int wordLen = words[i].length;
      int spaceNeeded = currentGroup.isEmpty ? 0 : 1;
      if (currentLen + spaceNeeded + wordLen <= maxCharsPerRow) {
        currentGroup.add(words[i]);
        currentLen += spaceNeeded + wordLen;
      } else {
        if (currentGroup.isNotEmpty) groupedWords.add(List.from(currentGroup));
        currentGroup = [words[i]];
        currentLen = wordLen;
      }
    }
    if (currentGroup.isNotEmpty) groupedWords.add(currentGroup);

    // Tìm số lượng ô lớn nhất trên 1 dòng để căn giữa các dòng còn lại
    int maxRowLen = 0;
    for (var group in groupedWords) {
      int len = group.fold(0, (prev, w) => prev + w.length) + (group.length - 1);
      if (len > maxRowLen) maxRowLen = len;
    }
    double maxRowWidth = maxRowLen * size + (maxRowLen - 1) * size * 0.1;

    // Render từng dòng
    for (int groupIdx = 0; groupIdx < groupedWords.length; groupIdx++) {
      var group = groupedWords[groupIdx];
      int rowLen = group.fold(0, (prev, w) => prev + w.length) + (group.length - 1);
      List<Widget> row = [];
      for (int i = 0; i < group.length; i++) {
        for (int j = 0; j < group[i].length; j++) {
          row.add(_buildAnswerBox(slotIdx++, slots, size));
          if (j < group[i].length - 1) {
            row.add(SizedBox(width: size * 0.1));
          }
        }
        if (i < group.length - 1) {
          row.add(SizedBox(width: size * 1.25));
        }
      }
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row,
        ),
      );
      if (groupIdx < groupedWords.length - 1) {
        rows.add(SizedBox(height: size * 0.1));
      }
    }
    return rows;
  }

  Widget _buildAnswerBox(int slotIdx, List<String> slots, double size) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _onAnswerSlotTap(slotIdx);
      },
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          double rotationAngle = (isCorrect || isWrong) ? 0.3 * sin(0.5 * _shakeAnimation.value) : 0;

          BoxDecoration boxDecoration;
          Color textColor = const Color(0xFF556B2F);

          if (isCorrect) {
            boxDecoration = BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/Correct.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(8),
            );
            textColor = Colors.white;
          } else if (isWrong) {
            boxDecoration = BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/Incorrect.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(8),
            );
            textColor = Colors.white;
          } else {
            boxDecoration = BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            );
            textColor = const Color(0xFF556B2F);
          }

          return Transform.rotate(
            angle: rotationAngle,
            child: Container(
              width: size,
              height: size,
              margin: const EdgeInsets.all(2.0),
              decoration: boxDecoration,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: slots[slotIdx].isNotEmpty
                    ? Text(
                  slots[slotIdx],
                  key: ValueKey('answer_${slotIdx}_${slots[slotIdx]}'),
                  style: TextStyle(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                )
                    : const SizedBox.shrink(key: ValueKey('empty_answer')),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadAllDataAndInitGame() async {
    try {
      final loadedQuestions = await QuestionService.loadQuestions();
      setState(() {
        questions = loadedQuestions;
        _isLoadingQuestions = false;
      });

      if (questions.isNotEmpty) {
        if (widget.initialLevel > 1) {
          level = min(widget.initialLevel, questions.length);
          currentQuestion = level - 1;
        } else {
          currentQuestion = 0;
          level = 1;
        }
        _initGame();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _preloadNextImage(currentQuestion + 1);
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải hoặc khởi tạo game: $e');
      setState(() {
        _isLoadingQuestions = false;
      });
      // Có thể show dialog báo lỗi ở đây nếu muốn
    }
  }

  void _initAnimations() {
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  void _loadDiamonds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      diamonds = prefs.getInt('diamonds') ?? 0;
    });
  }

  Widget getBanner(BuildContext context, WidgetRef ref) {
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

// Widget getBanner(BuildContext context, WidgetRef ref) {
//   final double screenWidth = MediaQuery.of(context).size.width;
//   final double screenHeight = MediaQuery.of(context).size.height;
//   final double horizontalPadding = screenWidth * 0.025;
//
//   if (_isBannerAdReady && _bannerAd != null) {
//     return Container(
//       width: screenWidth - (2 * horizontalPadding),
//       height: screenHeight * 0.07,
//       alignment: Alignment.center,
//       child: AdWidget(ad: _bannerAd!),
//     );
//   } else {
//     return const SizedBox.shrink();
//   }
// }
}