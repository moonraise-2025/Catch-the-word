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
  ];
  

  int dailyCount = 0; //  Biến đếm nhiệm vụ ngày
  int daily30Count = 0; //  Biến đếm nhiệm vụ tuần: 30 câu
  int daily50Count = 0; //  Biến đếm nhiệm vụ tuần: 50 câu

  int currentQuestion = 0; //giải thích: Chỉ số câu hỏi hiện tại
  int level = 1; //giải thích: Level hiện tại
  int diamonds = 0; //giải thích: Số kim cương hiện có

  late List<String> answerSlots; //giải thích: Danh sách ký tự đã điền vào đáp án
  late List<String> charOptions; //giải thích: Danh sách ký tự lựa chọn bên dưới
  late List<bool> charUsed; //giải thích: Trạng thái đã chọn của từng ký tự
  int currentSlot = 0; //giải thích: Vị trí ô đáp án hiện tại
  bool isCorrect = false; //giải thích: Trạng thái đúng/sai của đáp án

  Timer? _hintTimer;
  int _hintSeconds = 20;
  bool _hintActive = false;
  bool _hintUsedOnce = false;
  String? _hintBanner;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool isWrong = false;
  late final int maxAnswerLength;
  late double bannerHeight;

  final GlobalKey previewContainerKey = GlobalKey();
  Future<void> captureAndShareWidget() async {
    try {
      RenderRepaintBoundary boundary = previewContainerKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
        return captureAndShareWidget();
      }
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/screenshot.png').writeAsBytes(pngBytes);
        await Share.shareFiles([file.path], text: 'Chơi game Đuổi hình bắt chữ nè!');
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
    maxAnswerLength = questions.map((q) => q.answer.length).reduce((a, b) => a > b ? a : b);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 6 * 2 * 3.1415926535).animate(
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
    super.dispose();
  }

  void _initGame() {
    final answer = questions[currentQuestion].answer.toUpperCase();
    answerSlots = List.filled(answer.length, '');
    charOptions = _generateCharOptions(answer);
    charUsed = List.filled(charOptions.length, false);
    currentSlot = 0;
    isCorrect = false;
    _controller.reset();
    _controller.forward();
    _hintBanner = null;
    _hintUsedOnce = false;
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
    if (currentSlot < answerSlots.length && !charUsed[idx]) {
      setState(() {
        answerSlots[currentSlot] = charOptions[idx];
        charUsed[idx] = true;
        currentSlot++;
      });

      if (currentSlot == answerSlots.length) {
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
              final answer = correctAnswer;
              answerSlots = List.filled(answer.length, '');
              charOptions = _generateCharOptions(answer);
              charUsed = List.filled(charOptions.length, false);
              currentSlot = 0;
              isCorrect = false;
            });
          });
        }
      }
    }
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

  void _onAnswerSlotTap(int slotIndex) {
    if (answerSlots[slotIndex].isNotEmpty) {
      setState(() {
        String char = answerSlots[slotIndex];
        int idx = charOptions.indexOf(char);
        if (idx != -1) {
          charUsed[idx] = false;
        }
        answerSlots[slotIndex] = '';
        currentSlot = slotIndex;
        isCorrect = false;
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
        builder: (context) => AlertDialog(
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
      builder: (context) => AlertDialog(
        title: const Text('Hiện đáp án'),
        content: const Text('Bạn có muốn dùng 10 kim cương để mở 1 chữ không?'),
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
    final answer = questions[currentQuestion].answer.toUpperCase();
    String hint = answer.substring(0, 1);
    setState(() {
      _hintBanner = hint;
      _hintUsedOnce = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double imageContainerSize = screenWidth;
    bannerHeight = screenHeight * 0.05;
    final double smallPadding = screenWidth * 0.02;
    final double mediumPadding = screenWidth * 0.04;

    const int maxPerRow = 8;
    int row1Count = answerSlots.length > maxPerRow ? maxPerRow : answerSlots.length;
    int row2Count = answerSlots.length > maxPerRow ? answerSlots.length - maxPerRow : 0;

    // Adjust size to fit screen width, scaled down to 80% of original size
    final double adjustedSize = (screenWidth - 2 * mediumPadding - (maxPerRow + 1) * 4.0) / maxPerRow * 0.8;

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
                padding: EdgeInsets.symmetric(horizontal: mediumPadding, vertical: smallPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home, size: 45, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Level ', style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('$level', style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.yellow)),
                        SizedBox(width: mediumPadding),
                        Icon(Icons.diamond, color: Colors.blue[50], size: 45),
                        SizedBox(width: smallPadding),
                        Text('$diamonds', style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Giftpopup(
                            dailyCount: dailyCount,
                            daily30Count: daily30Count,
                            daily50Count: daily50Count,
                            onReward: (amount) async {
                              setState(() {
                                diamonds += amount;
                              });
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setInt('diamonds', diamonds);
                            },
                          ),
                        );
                      },
                      child: const Icon(Icons.card_giftcard, color: Colors.white, size: 45),
                    ),
                  ],
                ),
              ),
              // Spacer đẩy riêng cụm ảnh + banner xuống giữa
              SizedBox(height: 150),
              // Ảnh
              Container(
                margin: EdgeInsets.symmetric(horizontal: mediumPadding),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double imageBoxSize = constraints.maxWidth;
                        return Container(
                          width: imageBoxSize,
                          height: imageBoxSize, // hình vuông
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/questions/${questions[currentQuestion].imageName}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Text('Không thể tải ảnh'));
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Banner
              Container(
                margin: EdgeInsets.symmetric(horizontal: mediumPadding, vertical: 8),
                width: double.infinity,
                height: bannerHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/banner.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(10),
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
                          height: bannerHeight * 0.8,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: mediumPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (row1Count > 0) buildAnswerRow(0, row1Count, adjustedSize),
                            if (row2Count > 0) Padding(
                              padding: EdgeInsets.only(top: smallPadding),
                              child: buildAnswerRow(maxPerRow, row2Count, adjustedSize),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 90),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: mediumPadding, vertical: smallPadding),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: buildCharRow(0, charOptions.length, adjustedSize),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 50),
              Padding(
                padding: EdgeInsets.all(mediumPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showRevealLetterDialog,
                        icon: const Icon(Icons.key_outlined, size: 40),
                        label: const Text('Hiện đáp án', style: TextStyle(fontSize: 24)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[200],
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(width: mediumPadding),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: captureAndShareWidget,
                        icon: const Icon(Icons.share_outlined, size: 40),
                        label: const Text('Hỏi bạn bè', style: TextStyle(fontSize: 24)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[200],
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(width: mediumPadding),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_hintActive || _hintUsedOnce) ? null : () => _onHint(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[100],
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Gợi ý', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            if (_hintActive) Text('(${_hintSeconds}s)', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildCharRow(int start, int end, double size) {
    return List.generate(
      end - start,
      (i) => i + start < charOptions.length
          ? charUsed[i + start]
              ? SizedBox(width: size, height: size)
              : GestureDetector(
                  onTap: () => _onCharTap(i + start),
                  child: Container(
                    width: size,
                    height: size,
                    margin: const EdgeInsets.all(6),
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
                        fontSize: size * 0.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
          : SizedBox(width: size, height: size),
    );
  }

  Widget buildAnswerRow(int start, int count, double size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.all(4.0),
          child: GestureDetector(
            onTap: () => _onAnswerSlotTap(start + i),
            child: Container(
              width: size,
              height: size,
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
                  answerSlots[start + i],
                  style: TextStyle(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.bold,
                    color: currentSlot == answerSlots.length
                        ? (isCorrect ? Colors.green : Colors.red)
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}