import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';
import 'PopupAnswerCorrect.dart';
import 'PopupWatchVideo.dart';
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

class Question {
  final String imageName;
  final String answer;

  Question({required this.imageName, required this.answer});
}

class GameScreen extends StatefulWidget {
  final int initialLevel;

  const GameScreen({super.key, this.initialLevel = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final List<Question> questions = [
    Question(imageName: 'cau1.png', answer: 'CƯỚPBIỂN'),
    Question(imageName: 'cau2.png', answer: 'THUỶTINH'),
    Question(imageName: 'cau3.png', answer: 'GIẤUĐẦULÒIĐUÔI'),
    Question(imageName: 'cau4.png', answer: 'ĂNNĂN'),
    Question(imageName: 'cau5.png', answer: 'QUẠTTHAN'),
    Question(imageName: 'cau6.png', answer: 'CẦUHÔN'),
    Question(imageName: 'cau7.png', answer: 'CHÂNDUNG'),
    Question(imageName: 'cau8.png', answer: 'GIẢITHƯỞNG'),
    Question(imageName: 'cau9.png', answer: 'ĐẦUTƯ'),
    Question(imageName: 'cau10.png', answer: 'BÀNBẠC'),
    Question(imageName: 'cau11.png', answer: 'RAUMÁ'),
    Question(imageName: 'cau12.png', answer: 'MẮTNAI'),
    Question(imageName: 'cau13.png', answer: 'LƯỠIDAO'),
    Question(imageName: 'cau14.png', answer: 'NÓIDỐI'),
    Question(imageName: 'cau15.png', answer: 'MỞLÒNG'),
    Question(imageName: 'cau16.png', answer: 'HOAMẮT'),
    Question(imageName: 'cau17.png', answer: 'CHẠYNƯỚCRÚT'),
    Question(imageName: 'cau18.png', answer: 'TAYCHÂN'),
    Question(imageName: 'cau19.png', answer: 'CÁCHÉP'),
    Question(imageName: 'cau20.png', answer: 'CÂYCẦU'),
  ];

  int dailyCount = 0; //  Biến đếm nhiệm vụ ngày
  int daily30Count = 0; //  Biến đếm nhiệm vụ tuần: 30 câu
  int daily50Count = 0; //  Biến đếm nhiệm vụ tuần: 50 câu

  int currentQuestion = 0; //giải thích: Chỉ số câu hỏi hiện tại
  int level = 1; //giải thích: Level hiện tại
  int diamonds = 0; //giải thích: Số kim cương hiện có

  late List<String>
  answerSlots; //giải thích: Danh sách ký tự đã điền vào đáp án
  late List<String> charOptions; //giải thích: Danh sách ký tự lựa chọn bên dưới
  late List<int?> answerCharIndexes; // Lưu chỉ mục của charOptions
  late List<bool> charUsed; //giải thích: Trạng thái đã chọn của từng ký tự
  int currentSlot = 0; //giải thích: Vị trí ô đáp án hiện tại
  bool isCorrect = false; //giải thích: Trạng thái đúng/sai của đáp án

  Timer? _hintTimer;
  int _hintSeconds = 20;
  bool _hintActive = false;
  bool _hintUsedOnce = false;
  String? _hintBanner;
  int _hintWordIndex = 0;

  Timer? _askFriendInitialTimer;
  int _askFriendInitialSeconds = 30;
  bool _askFriendInitialActive = true;
  bool _askFriendUsedOnce = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool isWrong = false;
  late final int maxAnswerLength;
  late double bannerHeight;

  final GlobalKey previewContainerKey = GlobalKey();
  int dummyState = 0; // Biến phụ để force rebuild UI nếu cần

  Future<void> captureAndShareWidget() async {
    if (_askFriendInitialActive || _askFriendUsedOnce) {
      return;
    }
    try {
      RenderRepaintBoundary boundary = previewContainerKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
        return captureAndShareWidget();
      }
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file =
        await File('${tempDir.path}/screenshot.png').writeAsBytes(pngBytes);
        await Share.shareFiles([file.path],
            text: 'Chơi game Đuổi hình bắt chữ nè!');
        setState(() {
          _askFriendUsedOnce = true;
        });
      }
    } catch (e) {
      debugPrint('Lỗi chụp/chia sẻ widget: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLevel > 1) {
      level = widget.initialLevel;
      currentQuestion = widget.initialLevel - 1;
    }
    maxAnswerLength =
        questions.map((q) => q.answer.length).reduce((a, b) => a > b ? a : b);
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
    _initGame();

    checkAndResetDailyProgress();
    _loadDiamonds();
  }

  Future<void> _loadDiamonds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      diamonds = prefs.getInt('diamonds') ?? 0;
    });
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

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _hintTimer?.cancel();
    _askFriendInitialTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    final answer = questions[currentQuestion].answer.toUpperCase();
    answerSlots = List.filled(answer.length, '');
    answerCharIndexes =
        List.filled(answer.length, null); // Khởi tạo chỉ mục là null
    charOptions = _generateCharOptions(answer);
    charUsed = List.filled(charOptions.length, false);
    currentSlot = 0;
    isCorrect = false;
    _controller.reset();
    _controller.forward();
    _hintBanner = null;
    _hintUsedOnce = false;
    _hintWordIndex = 0;
    _askFriendInitialActive = true;
    _askFriendInitialSeconds = 30;
    _askFriendUsedOnce = false;
    _askFriendInitialTimer?.cancel();
    _startAskFriendInitialCountdown();
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
    while (chars.length < answer.length + numDistractors) {
      String c = alphabet[rnd.nextInt(alphabet.length)];
      if (!answer.contains(c)) {
        chars.add(c);
      }
    }
    chars.shuffle();
    return chars;
  }

  void _onCharTap(int idx) async {
    // Tìm ô trống đầu tiên để điền vào
    int targetSlot = answerSlots.indexOf('');
    // Nếu không còn ô trống nào, không làm gì cả
    if (targetSlot == -1) {
      return;
    }
    // Nếu ký tự đã được sử dụng, cũng không làm gì cả
    if (charUsed[idx]) {
      return;
    }

    setState(() {
      answerSlots[targetSlot] = charOptions[idx]; // Điền vào ô trống tìm được
      answerCharIndexes[targetSlot] = idx; // Lưu chỉ mục
      charUsed[idx] = true; // Đánh dấu đã sử dụng

      // Sau khi điền, cập nhật currentSlot để trỏ đến ô trống tiếp theo (nếu có)
      currentSlot = answerSlots.indexOf('');
      if (currentSlot == -1) {
        // Nếu tất cả các ô đã điền
        currentSlot = answerSlots.length; // Đặt về cuối
      }
    });

    // Kiểm tra đáp án nếu tất cả các ô đã được điền
    if (currentSlot == answerSlots.length) {
      // Dùng currentSlot sau khi cập nhật
      final userAnswer = answerSlots.join('');
      final correctAnswer = questions[currentQuestion].answer.toUpperCase();
      final correct = userAnswer == correctAnswer;

      setState(() {
        isCorrect = correct;
      });

      if (correct) {
        Future.delayed(const Duration(milliseconds: 300), showCorrectDialog);

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

        _shakeController.forward(from: 0);

        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            isWrong = false;
            final answer = questions[currentQuestion].answer.toUpperCase();
            answerSlots = List.filled(answer.length, '');
            answerCharIndexes =
                List.filled(answer.length, null); // Đảm bảo reset cả cái này
            charOptions = _generateCharOptions(answer);
            charUsed = List.filled(charOptions.length, false);
            currentSlot = 0;
            isCorrect = false;
          });
        });
      }
    }
    // In ra để kiểm tra
    print(
        'Sau khi chọn: answerSlots = $answerSlots, charUsed = $charUsed, currentSlot = $currentSlot');
  }

  void _startHintCountdown() {
    setState(() {
      _hintSeconds = 20;
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

  void _startAskFriendInitialCountdown() {
    setState(() {
      _askFriendInitialSeconds = 30;
      _askFriendInitialActive = true;
    });

    _askFriendInitialTimer?.cancel();
    _askFriendInitialTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_askFriendInitialSeconds == 0) {
            timer.cancel();
            setState(() {
              _askFriendInitialActive = false;
            });
          } else {
            setState(() {
              _askFriendInitialSeconds--;
            });
          }
        });
  }

  // void _onAnswerSlotTap(int slotIndex) {
  //   if (answerCharIndexes[slotIndex] != null) { // Kiểm tra xem ô có chứa ký tự không
  //     setState(() {
  //       int? charIdxToReturn = answerCharIndexes[slotIndex]; // Lấy chỉ mục đã lưu
  //
  //       if (charIdxToReturn != null && charIdxToReturn != -1) {
  //         charUsed[charIdxToReturn] = false; // Đặt lại trạng thái 'đã sử dụng'
  //       }
  //       answerSlots[slotIndex] = ''; // Xóa chữ cái hiển thị
  //       answerCharIndexes[slotIndex] = null; // Xóa chỉ mục
  //       currentSlot = slotIndex;
  //       isCorrect = false;
  //     });
  //   }
  // }

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

        // Tìm ô trống đầu tiên từ bên trái
        // Đặt currentSlot về vị trí của ô trống sớm nhất
        currentSlot = answerSlots.indexOf('');
        if (currentSlot == -1) {
          // Nếu không có ô trống nào (tức là tất cả đã điền)
          currentSlot = answerSlots.length; // Đặt về cuối để tránh lỗi
        }

        // In ra để kiểm tra
        print(
            'Sau khi xóa: answerSlots = $answerSlots, charUsed = $charUsed, currentSlot = $currentSlot');
      });
    }
  }

  void showCorrectDialog() {
    AudioManager().playNextLevelSound();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopupAnswerCorrect(
          onNext: () async {
            Navigator.of(context).pop();
            setState(() async {
              if (currentQuestion < questions.length - 1) {
                currentQuestion++;
                level++;
                diamonds += 5;
                _initGame();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('lastLevel', level);
                await prefs.setInt('diamonds', diamonds);
              } else {
                currentQuestion = 0;
                level = 1;
                diamonds = 0;
                _initGame();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('lastLevel', 1);
                await prefs.setInt('diamonds', diamonds);
              }
            });
          },
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
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text('Không đủ kim cương'),
              content: const Text('Bạn không đủ 10 kim cương để mở 1 chữ!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }
    final shouldReveal = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Hiện đáp án'),
            content: const Text(
                'Bạn có muốn dùng 10 kim cương để mở 1 chữ không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Đồng ý'),
              ),
            ],
          ),
    );
    if (shouldReveal == true) {
      setState(() {
        diamonds -= 10;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('diamonds', diamonds);
      setState(() {
        final answer = questions[currentQuestion].answer.toUpperCase();
        for (int i = 0; i < answerSlots.length; i++) {
          if (answerSlots[i].isEmpty) {
            String correctChar = answer[i];
            for (int j = 0; j < charOptions.length; j++) {
              if (charOptions[j] == correctChar && !charUsed[j]) {
                answerSlots[i] = correctChar;
                charUsed[j] = true;
                currentSlot = i + 1;
                break;
              }
            }
            break;
          }
        }
      });
    }
  }

  void _onHint() {
    if (_hintActive) return;
    final customHints = [
      'CƯỚP',
      'THUỶ',
      'GIẤU',
      'ĂN',
      'QUẠT',
      'CẦU',
      'CHÂN',
      'THƯỞNG',
      'TƯ',
      'BÀN',
      'MÁ',
      'MẮT',
      'DAO',
      'NÓI',
      'MỞ',
      'HOA',
      'CHẠY',
      'TAY',
    ];
    String hint = '';
    if (currentQuestion >= 0 && currentQuestion < customHints.length) {
      hint = customHints[currentQuestion];
    }
    setState(() {
      _hintBanner = hint;
      _hintUsedOnce = true;
    });
  }

  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('lastLevel', currentQuestion + 1);
    // await prefs.setInt('diamonds', diamonds);
    // await prefs.setInt('dailyCount', dailyCount);
    // await prefs.setInt('daily30Count', daily30Count);
    // await prefs.setInt('daily50Count', daily50Count);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    final double imageContainerSize = screenWidth * 0.7;
    bannerHeight = screenHeight * 0.045;
    final double smallPadding = screenWidth * 0.025;
    final double mediumPadding = screenWidth * 0.05;

    const int maxPerRow = 8;
    int row1Count =
    answerSlots.length > maxPerRow ? maxPerRow : answerSlots.length;
    int row2Count =
    answerSlots.length > maxPerRow ? answerSlots.length - maxPerRow : 0;

    // Adjust size to fit screen width, scaled down to 80% of original size
    final double adjustedSize =
        (screenWidth - 2 * mediumPadding - (maxPerRow + 1) * 4.0) /
            maxPerRow *
            0.85;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/BackgroundDHBC.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header luôn ở trên cùng
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
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  Giftpopup(
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
                                  ),
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

              // Spacer đẩy riêng cụm ảnh + banner xuống giữa

//                 Expanded(
//                 child: RepaintBoundary(
//                   key: previewContainerKey, bọc vào để ảnh
              SizedBox(height: screenHeight * 0.01),
              Expanded(
                child: RepaintBoundary(
                  key: previewContainerKey,
                  child: Column( // Use a Column to hold the image and banner
                      children: [
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: mediumPadding),
                          width: double.infinity,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double imageBoxSize = constraints
                                      .maxWidth;
                                  return Container(
                                    width: imageBoxSize,
                                    height: imageBoxSize * 0.6,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black26),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        'assets/questions/${questions[currentQuestion]
                                            .imageName}',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: mediumPadding, vertical: 4),
                          width: double.infinity,
                          height: bannerHeight,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/banner.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _hintBanner != null
                                ? Text(
                              _hintBanner!,
                              style: TextStyle(
                                fontSize: bannerHeight * 0.6,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            )
                                : Image.asset(
                              'assets/images/logo3-15dhbc.png',
                              height: bannerHeight * 2.5,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: mediumPadding),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center,
                                    children: [
                                      ..._buildAnswerRows(
                                          answerSlots,
                                          questions[currentQuestion]
                                              .answer
                                              .toUpperCase(),
                                          adjustedSize),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.only(
                                        left: mediumPadding,
                                        right: mediumPadding,
                                        bottom: screenHeight * 0.01),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: screenWidth * 0.03,
                                      runSpacing: screenWidth * 0.03,
                                      children: buildCharRow(
                                          0, charOptions.length, adjustedSize),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              Padding(
                padding: EdgeInsets.all(screenWidth * 0.027),
                child: Column(
                  children: [
                  SizedBox(
                  height: screenHeight * 0.07,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: screenWidth * 0.31,
                        child: ElevatedButton(
                          onPressed: _showRevealLetterDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF90C240),
                            disabledBackgroundColor: const Color(0xFF90C240).withOpacity(0.6),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.black,
                                width: screenWidth * 0.002,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Hiện Đáp Án',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                  )),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '10 ',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Image.asset(
                                        'assets/images/Diamond_Borderless.png',
                                        width: screenWidth * 0.04,
                                        height: screenWidth * 0.04,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: screenWidth * 0.001),
                      SizedBox(
                        width: screenWidth * 0.31,
                        child: ElevatedButton.icon(
                          onPressed:
                          (_askFriendInitialActive || _askFriendUsedOnce)
                              ? null
                              : captureAndShareWidget,
                          label: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Hỏi Bạn ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (_askFriendInitialActive ||
                                          _askFriendUsedOnce)
                                          ? Colors.white70
                                          : Colors.white,
                                      fontSize: screenWidth * 0.045)),
                              if (_askFriendInitialActive)
                                Text('${_askFriendInitialSeconds}s',
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.white70)),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  Color(0xFFF8B52E),
                            disabledBackgroundColor: Color(0xFFF8B52E).withOpacity(0.6),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: (_askFriendInitialActive ||
                                      _askFriendUsedOnce)
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.black,
                                  width: screenWidth * 0.002),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.001),
                      SizedBox(
                        width: screenWidth * 0.31,
                        child: ElevatedButton(
                          onPressed: (_hintActive || _hintUsedOnce)
                              ? null
                              : () => _onHint(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF3A3C5),
                            disabledBackgroundColor: Color(0xFFF3A3C5).withOpacity(0.6),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: (_hintActive || _hintUsedOnce)
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.black,
                                  width: screenWidth * 0.002),
                            ),
                          ),
                          child: Column(
                            //mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Gợi Ý',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (_hintActive || _hintUsedOnce)
                                        ? Colors.white70
                                        : Colors.white,
                                    fontSize: screenWidth * 0.045,
                                  )),
                              if (_hintActive)
                                Text('${_hintSeconds}s',
                                    style: TextStyle( color: Colors.white70,fontSize: screenWidth * 0.03)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: smallPadding,),
                Visibility(
                    visible: true,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "QUA MÀN\n",
                                  style: TextStyle(
                                    color: Color(0xFF616FD3),
                                    fontSize: screenWidth * 0.07,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: "(Quảng cáo 15s~30s)",
                                  style: TextStyle(
                                    color: Color(0xFF43ADED),
                                    fontSize: screenWidth * 0.03,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ),
                    )
                )
                    ]),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildCharRow(int start, int end, double size) {
    final double bigSize = size * 1.25;
    return List.generate(
      end - start,
          (i) =>
          SizedBox(
            width: bigSize,
            height: bigSize,
            child: charUsed[i + start]
                ? const SizedBox.shrink()
                : GestureDetector(
              onTap: () => _onCharTap(i + start),
              child: Container(
                margin: EdgeInsets.all(bigSize * 0.12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  charOptions[i + start],
                  style: TextStyle(
                    fontSize: bigSize * 0.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
    );
  }

  List<Widget> _buildAnswerRows(List<String> slots, String answer,
      double size) {
    final words = answer.split(' ');
    List<Widget> rows = [];
    int slotIdx = 0;

    if (words.length == 4) {
      // Dòng 1: từ 1, 2
      List<Widget> row1 = [];
      for (int w = 0; w < 2; w++) {
        for (int i = 0; i < words[w].length; i++) {
          row1.add(_buildAnswerBox(slotIdx++, slots, size));
        }
        if (w == 0) row1.add(SizedBox(width: size * 0.5));
      }
      rows.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: row1));
      rows.add(SizedBox(height: size * 0.5));
      // Dòng 2: từ 3, 4
      List<Widget> row2 = [];
      for (int w = 2; w < 4; w++) {
        for (int i = 0; i < words[w].length; i++) {
          row2.add(_buildAnswerBox(slotIdx++, slots, size));
        }
        if (w == 2) row2.add(SizedBox(width: size * 0.5));
      }
      rows.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: row2));
    } else if (words.length == 3) {
      // Dòng 1: từ 1
      List<Widget> row1 = [];
      for (int i = 0; i < words[0].length; i++) {
        row1.add(_buildAnswerBox(slotIdx++, slots, size));
      }
      rows.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: row1));
      rows.add(SizedBox(height: size * 0.5));
      // Dòng 2: từ 2, 3
      List<Widget> row2 = [];
      for (int w = 1; w < 3; w++) {
        for (int i = 0; i < words[w].length; i++) {
          row2.add(_buildAnswerBox(slotIdx++, slots, size));
        }
        if (w == 1) row2.add(SizedBox(width: size * 0.5));
      }
      rows.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: row2));
    } else if (words.length == 2) {
      // Dòng 1: từ 1
      List<Widget> row1 = [];
      for (int i = 0; i < words[0].length; i++) {
        row1.add(_buildAnswerBox(slotIdx++, slots, size));
      }
      rows.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: row1));
      rows.add(SizedBox(height: size * 0.5));
      // Dòng 2: từ 2
      List<Widget> row2 = [];
      for (int i = 0; i < words[1].length; i++) {
        row2.add(_buildAnswerBox(slotIdx++, slots, size));
      }
      rows.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: row2));
    } else {
      // 1 từ: tất cả trên 1 dòng
      List<Widget> row = [];
      for (int i = 0; i < words[0].length; i++) {
        row.add(_buildAnswerBox(slotIdx++, slots, size));
      }
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row));
    }
    return rows;
  }

  Widget _buildAnswerBox(int slotIdx, List<String> slots, double size) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _onAnswerSlotTap(slotIdx);
      },
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.symmetric(
            horizontal: size * 0.02, vertical: size * 0.02),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            double offset = isWrong ? 10 * sin(_shakeAnimation.value) : 0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Text(
            slots[slotIdx],
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              color: (!answerSlots.contains(''))
                  ? (isCorrect
                  ? Colors.green
                  : (isWrong ? Colors.red : Colors.black))
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
