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
    Question(imageName: 'cau1.png', answer: 'CƯỚP BIỂN'),
    Question(imageName: 'cau2.png', answer: 'THUỶ TINH'),
    Question(imageName: 'cau3.png', answer: 'GIẤU ĐẦU LÒI ĐUÔI'),
    Question(imageName: 'cau4.png', answer: 'ĂN NĂN'),
    Question(imageName: 'cau5.png', answer: 'QUẠT THAN'),
    Question(imageName: 'cau6.png', answer: 'CẦU HÔN'),
    Question(imageName: 'cau7.png', answer: 'CHÂN DUNG'),
    Question(imageName: 'cau8.png', answer: 'GIẢI THƯỞNG'),
    Question(imageName: 'cau9.png', answer: 'ĐẦU TƯ'),
    Question(imageName: 'cau10.png', answer: 'BÀN BẠC'),
    Question(imageName: 'cau11.png', answer: 'RAU MÁ'),
    Question(imageName: 'cau12.png', answer: 'MẮT NAI'),
    Question(imageName: 'cau13.png', answer: 'LƯỠI DAO'),
    Question(imageName: 'cau14.png', answer: 'NÓI DỐI'),
    Question(imageName: 'cau15.png', answer: 'MỞ LÒNG'),
    Question(imageName: 'cau16.png', answer: 'HOA MẮT'),
    Question(imageName: 'cau17.png', answer: 'CHẠY NƯỚC RÚT'),
    Question(imageName: 'cau18.png', answer: 'TAY CHÂN'),
  ];
  
  int dailyCount = 0;
  int daily30Count = 0;
  int daily50Count = 0;
  
  int currentQuestion = 0;
  int level = 1;
  int diamonds = 0;

  late List<String> answerSlots;
  late List<String> charOptions;
  late List<bool> charUsed;
  late List<int?> answerSlotToCharOptionIndex;
  int currentSlot = 0;
  bool isCorrect = false;
  Timer? _hintTimer;
  int _hintSeconds = 12;
  bool _hintActive = false;
  bool _hintUsedOnce = false;
  String? _hintBanner;
  int _hintWordIndex = 0;

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
    final answerNoSpace = answer.replaceAll(' ', '');
    answerSlots = List.filled(answerNoSpace.length, '');
    charOptions = _generateCharOptions(answerNoSpace);
    charUsed = List.filled(charOptions.length, false);
    answerSlotToCharOptionIndex = List.filled(answerSlots.length, null);
    currentSlot = 0;
    isCorrect = false;
    _controller.reset();
    _controller.forward();
    _hintBanner = null;
    _hintUsedOnce = false;
    _hintWordIndex = 0;
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
    // Tìm ô trống đầu tiên từ trái sang phải
    int firstEmpty = answerSlots.indexWhere((c) => c.isEmpty);
    if (firstEmpty != -1 && !charUsed[idx]) {
      setState(() {
        answerSlots[firstEmpty] = charOptions[idx];
        charUsed[idx] = true;
        answerSlotToCharOptionIndex[firstEmpty] = idx;
        currentSlot = answerSlots.indexWhere((c) => c.isEmpty);
      });

      if (!answerSlots.contains('')) {
        final userAnswer = answerSlots.join('');
        final correctAnswer = questions[currentQuestion].answer.toUpperCase().replaceAll(' ', '');
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
              final answerNoSpace = answer.replaceAll(' ', '');
              answerSlots = List.filled(answerNoSpace.length, '');
              charOptions = _generateCharOptions(answerNoSpace);
              charUsed = List.filled(charOptions.length, false);
              answerSlotToCharOptionIndex = List.filled(answerNoSpace.length, null);
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
      _hintSeconds = 12;
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
        int? idx = answerSlotToCharOptionIndex[slotIndex];
        if (idx != null) {
          charUsed[idx] = false;
        }
        answerSlots[slotIndex] = '';
        answerSlotToCharOptionIndex[slotIndex] = null;
        currentSlot = slotIndex;
        isCorrect = false;
        isWrong = false;
        dummyState++;
      });
    }
  }

  void showCorrectDialog() {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double imageContainerSize = screenWidth * 0.7;
    bannerHeight = screenHeight * 0.045;
    final double smallPadding = screenWidth * 0.025;
    final double mediumPadding = screenWidth * 0.05;

    const int maxPerRow = 8;
    int row1Count = answerSlots.length > maxPerRow ? maxPerRow : answerSlots.length;
    int row2Count = answerSlots.length > maxPerRow ? answerSlots.length - maxPerRow : 0;

    // Adjust size to fit screen width, scaled down to 80% of original size
    final double adjustedSize = (screenWidth - 2 * mediumPadding - (maxPerRow + 1) * 4.0) / maxPerRow * 0.85;

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
                      icon: Icon(Icons.home, size: screenWidth * 0.09, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Level ', style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('$level', style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold, color: Colors.yellow)),
                        SizedBox(width: mediumPadding),
                        Icon(Icons.diamond, color: Colors.blue[50], size: screenWidth * 0.06),
                        SizedBox(width: smallPadding),
                        Text('$diamonds', style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      child: Icon(Icons.card_giftcard, color: Colors.white, size: screenWidth * 0.06),
                    ),
                  ],
                ),
              ),
              // Spacer đẩy riêng cụm ảnh + banner xuống giữa
              SizedBox(height: screenHeight * 0.01),
              // Ảnh
              Container(
                margin: EdgeInsets.symmetric(horizontal: mediumPadding),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double imageBoxSize = imageContainerSize;
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
                margin: EdgeInsets.symmetric(horizontal: mediumPadding, vertical: 4),
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
              SizedBox(height: screenHeight * 0.012),
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
                            ..._buildAnswerRows(answerSlots, questions[currentQuestion].answer.toUpperCase(), adjustedSize),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(left: mediumPadding, right: mediumPadding, bottom: screenHeight * 0.01),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: screenWidth * 0.03,
                            runSpacing: screenWidth * 0.03,
                            children: buildCharRow(0, charOptions.length, adjustedSize),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Padding(
                padding: EdgeInsets.all(mediumPadding),
                child: SizedBox(
                  height: screenHeight * 0.08,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showRevealLetterDialog,
                          icon: Icon(Icons.key_outlined, size: screenWidth * 0.06),
                          label: Text('Hiện đáp án', style: TextStyle(fontSize: screenWidth * 0.03)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[200],
                            padding: EdgeInsets.symmetric(vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      SizedBox(width: mediumPadding),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: captureAndShareWidget,
                          icon: Icon(Icons.share_outlined, size: screenWidth * 0.06),
                          label: Text('Hỏi bạn bè', style: TextStyle(fontSize: screenWidth * 0.03)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[200],
                            padding: EdgeInsets.symmetric(vertical: 0),
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
                            padding: EdgeInsets.symmetric(vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Column(
                            //mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Gợi ý', style: TextStyle(fontSize: screenWidth * 0.03, fontWeight: FontWeight.bold)),
                              if (_hintActive) Text('(${_hintSeconds}s)', style: TextStyle(fontSize: screenWidth * 0.03)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      (i) => SizedBox(
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

  List<Widget> _buildAnswerRows(List<String> slots, String answer, double size) {
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
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row1));
      rows.add(SizedBox(height: size * 0.5));
      // Dòng 2: từ 3, 4
      List<Widget> row2 = [];
      for (int w = 2; w < 4; w++) {
        for (int i = 0; i < words[w].length; i++) {
          row2.add(_buildAnswerBox(slotIdx++, slots, size));
        }
        if (w == 2) row2.add(SizedBox(width: size * 0.5));
      }
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row2));
    } else if (words.length == 3) {
      // Dòng 1: từ 1
      List<Widget> row1 = [];
      for (int i = 0; i < words[0].length; i++) {
        row1.add(_buildAnswerBox(slotIdx++, slots, size));
      }
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row1));
      rows.add(SizedBox(height: size * 0.5));
      // Dòng 2: từ 2, 3
      List<Widget> row2 = [];
      for (int w = 1; w < 3; w++) {
        for (int i = 0; i < words[w].length; i++) {
          row2.add(_buildAnswerBox(slotIdx++, slots, size));
        }
        if (w == 1) row2.add(SizedBox(width: size * 0.5));
      }
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row2));
    } else if (words.length == 2) {
      // Dòng 1: từ 1
      List<Widget> row1 = [];
      for (int i = 0; i < words[0].length; i++) {
        row1.add(_buildAnswerBox(slotIdx++, slots, size));
      }
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row1));
      rows.add(SizedBox(height: size * 0.5));
      // Dòng 2: từ 2
      List<Widget> row2 = [];
      for (int i = 0; i < words[1].length; i++) {
        row2.add(_buildAnswerBox(slotIdx++, slots, size));
      }
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row2));
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
        margin: EdgeInsets.symmetric(horizontal: size * 0.08, vertical: size * 0.08),
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
                  ? (isCorrect ? Colors.green : (isWrong ? Colors.red : Colors.black))
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}