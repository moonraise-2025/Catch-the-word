import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

import 'package:duoihinhbatchu/model/question.dart'; // Đảm bảo đúng đường dẫn tới model/question.dart
import 'package:duoihinhbatchu/service/question_service.dart';


class GameScreen extends StatefulWidget {
  final int initialLevel;

  const GameScreen({super.key, this.initialLevel = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Thay thế danh sách questions cứng bằng một danh sách rỗng ban đầu
  // Dữ liệu sẽ được tải từ JSON
  List<Question> questions = [];
  bool _isLoadingQuestions = true; // Biến trạng thái để kiểm tra xem dữ liệu đã tải xong chưa

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
  int _hintSeconds = 20;
  bool _hintActive = false;
  bool _hintUsedOnce = false;
  String? _hintBanner;
  // int _hintWordIndex = 0; // Đã bỏ vì không được sử dụng

  // Timer? _askFriendInitialTimer;
  // int _askFriendInitialSeconds = 30;
  // bool _askFriendInitialActive = true;
  bool _askFriendUsedOnce = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool isWrong = false;
  late int maxAnswerLength; // Sẽ tính toán sau khi tải questions
  late double bannerHeight;

  final GlobalKey previewContainerKey = GlobalKey();
  // int dummyState = 0; // Biến này không được sử dụng

  Future<void> captureAndShareWidget() async {
    if (_askFriendUsedOnce) {
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
  }

  Future<void> _loadAllDataAndInitGame() async {
    // Tải danh sách câu hỏi từ QuestionService
    try {
      final loadedQuestions = await QuestionService.loadQuestions();
      setState(() {
        questions = loadedQuestions;
        _isLoadingQuestions = false; // Đã tải xong
      });

      if (questions.isNotEmpty) { // Chỉ khởi tạo game nếu có câu hỏi
        if (widget.initialLevel > 1) { // Đảm bảo initialLevel không vượt quá số lượng câu hỏi
          level = min(widget.initialLevel, questions.length);
          currentQuestion = level - 1;
        } else {
          currentQuestion = 0;
          level = 1;
        }
        // Đảm bảo rằng maxAnswerLength được tính sau khi questions được tải
        maxAnswerLength = questions.map((q) => q.answer.replaceAll(' ', '').length).reduce((a, b) => a > b ? a : b);
        _initGame(); // Khởi tạo game với câu hỏi đầu tiên (hoặc level được truyền vào)
      } else { // Xử lý trường hợp không có câu hỏi nào được tải (ví dụ: hiển thị lỗi hoặc quay về màn hình chính)
        debugPrint("Không có câu hỏi nào được tải từ JSON.");
        // Bạn có thể showDialog hoặc Navigator.pop ở đây
        // Để hiển thị lỗi trên màn hình như ảnh chụp, bạn có thể thiết lập một biến trạng thái lỗi
        // và hiển thị một widget Text dựa trên biến đó.
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Lỗi"),
                content: const Text("Không thể tải câu hỏi. Vui lòng kiểm tra file JSON hoặc đường dẫn."),
                actions: <Widget>[
                  TextButton(
                    child: const Text("Quay lại"),
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng dialog
                      Navigator.of(context).pop(); // Quay lại màn hình trước đó
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải hoặc khởi tạo game: $e');
      setState(() {
        _isLoadingQuestions = false; // Vẫn đặt false để dừng indicator
        // Tùy chọn, đặt trạng thái lỗi để hiển thị cho người dùng
      });
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Lỗi"),
              content: Text("Không thể tải câu hỏi. Vui lòng kiểm tra file JSON hoặc đường dẫn. Chi tiết: $e"),
              actions: <Widget>[
                TextButton(
                  child: const Text("Quay lại"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop(); // Quay lại màn hình trước đó
                  },
                ),
              ],
            );
          },
        );
      }
    }
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
    // _askFriendInitialTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    // Đảm bảo `questions` không rỗng trước khi truy cập
    if (questions.isEmpty) {
      debugPrint("Lỗi: Không có câu hỏi để khởi tạo game.");
      return;
    }

    final answer = questions[currentQuestion].answer.toUpperCase();
    answerSlots = List.filled(answer.replaceAll(' ', '').length,
        ''); // Chỉ đếm ký tự, bỏ khoảng trống

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
    // _hintWordIndex = 0;

    // _askFriendInitialActive = true;
    // _askFriendInitialSeconds = 30;
    _askFriendUsedOnce = false; // Đặt lại trạng thái đã dùng
    // _askFriendInitialTimer?.cancel();
    // _startAskFriendInitialCountdown();

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
        _shakeController.forward(from: 0);
        await Future.delayed(const Duration(seconds: 2));
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

        _shakeController.forward(from: 0);

        Future.delayed(const Duration(seconds: 2), () {
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

  // Phương thức _startAskFriendInitialCountdown đã được loại bỏ

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopupAnswerCorrect(
          onNext: () async {
            Navigator.of(context).pop();
            setState(() { // setState không cần async
              if (currentQuestion < questions.length - 1) {
                currentQuestion++;
                level++;
                diamonds += 5;
              } else {
                currentQuestion = 0;
                level = 1;
                diamonds = 0;
              }
              _initGame(); // Gọi _initGame sau khi cập nhật level/question
              _saveGameProgress(); // Lưu trạng thái game
              _saveDiamonds(); // Lưu kim cương
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
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          return AlertDialog(
            title: Text(
              'Không đủ kim cương',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                letterSpacing: 1.0,
              ),
            ),
            content: Text(
              'Bạn không đủ 10 kim cương để mở 1 chữ!',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }
    final shouldReveal = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          title: Text(
            'Hiện đáp án',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              letterSpacing: 1.2,
            ),
          ),
          content: Text(
            'Bạn có muốn dùng 10 kim cương để mở 1 chữ không?',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Không',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Đồng ý',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (shouldReveal == true) {
      setState(() {
        diamonds -= 10;
      });
      await _saveDiamonds();
      setState(() {
        final answer = questions[currentQuestion].answer.toUpperCase();
        for (int i = 0; i < answerSlots.length; i++) {
          if (answerSlots[i].isEmpty) {
            String correctChar =
            answer.replaceAll(' ', '')[i];
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
    final answer = questions[currentQuestion].answer.toUpperCase();
    final words = answer.split(' ');
    String hint = words[0];

    setState(() {
      _hintBanner = hint;
      _hintUsedOnce = true;
    });
  }

  Future<void> _saveGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastLevel', level); // Lưu level hiện tại
  }

  Future<void> _saveDiamonds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('diamonds', diamonds);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
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

    final double imageContainerSize = screenWidth * 0.7;
    bannerHeight = screenHeight * 0.045;
    final double smallPadding = screenWidth * 0.025;
    final double mediumPadding = screenWidth * 0.05;

    const int maxPerRow = 7;
    final answer = questions[currentQuestion].answer.toUpperCase();
    final double adjustedSize =
        (screenWidth - 2 * mediumPadding - (maxPerRow + 1) * 4.0) /
            maxPerRow *
            0.9;


    return Container(
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
            children: [
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
                              builder: (context) => Giftpopup(
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

              SizedBox(height: screenHeight * 0.001),
              Expanded(
                child: RepaintBoundary(
                  key: previewContainerKey,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.005),

                      Container(
                        margin: EdgeInsets.symmetric(horizontal: mediumPadding),
                        width: double.infinity,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double imageBoxSize =
                                    constraints.maxWidth;
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
                                    // SỬ DỤNG Image.network ĐỂ TẢI HÌNH ẢNH TỪ URL
                                    child: Image.network(
                                      questions[currentQuestion].imgQuestion,
                                      fit: BoxFit.contain,
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
                                          child: Icon(Icons.error, color: Colors.red, size: 50),
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
                      SizedBox(height: screenWidth * 0.005),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: mediumPadding),
                        width: double.infinity,
                        height: screenWidth * 0.10,
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
                              fontSize: bannerHeight * 0.4,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          )
                              : Image.asset(
                            'assets/images/logo3-15dhbc.png',
                            height: bannerHeight * 4.0,
                            fit: BoxFit.contain,
                          ),

                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: mediumPadding),
                                padding: EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  border:
                                  Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: adjustedSize * 3.2,

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _buildAnswerRows(
                                      answerSlots, answer, adjustedSize),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Expanded(
                                child: Column(
                                  children: buildCharRows(adjustedSize * 1.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.027),
                        child: Column(
                          children: [
                            SizedBox(
                              height: screenHeight * 0.07,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,

                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: screenWidth * 0.31,
                                    child: ElevatedButton(
                                      onPressed: _showRevealLetterDialog,
                                      style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF90C240),
                                        disabledBackgroundColor:
                                        const Color(0xFF90C240)
                                            .withOpacity(0.6),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),

                                          side: BorderSide(
                                            color: Colors.black,
                                            width: screenWidth * 0.002,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,

                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Hiện Đáp Án',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.045,
                                            ),
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '10 ',
                                                  style: TextStyle(
                                                    fontSize:
                                                    screenWidth * 0.03,

                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                WidgetSpan(
                                                  alignment:
                                                  PlaceholderAlignment
                                                      .middle,

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
                                    child: ElevatedButton(
                                      onPressed: _askFriendUsedOnce
                                          ? null
                                          : captureAndShareWidget,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFF8B52E),
                                        disabledBackgroundColor:
                                        Color(0xFFF8B52E).withOpacity(0.6),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          side: BorderSide(
                                              color: _askFriendUsedOnce
                                                  ? Colors.black.withOpacity(0.5)
                                                  : Colors.black,
                                              width: screenWidth * 0.002),
                                        ),
                                      ),
                                      child: Text( // Chỉ hiển thị Text, không còn countdown
                                        'Hỏi Bạn',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _askFriendUsedOnce
                                              ? Colors.white70
                                              : Colors.white,
                                          fontSize: screenWidth * 0.045,
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
                                        disabledBackgroundColor:
                                        Color(0xFFF3A3C5).withOpacity(0.6),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          side: BorderSide(
                                              color:
                                              (_hintActive || _hintUsedOnce)
                                                  ? Colors.black
                                                  .withOpacity(0.5)
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
                                                color: (_hintActive ||
                                                    _hintUsedOnce)

                                                    ? Colors.white70
                                                    : Colors.white,
                                                fontSize: screenWidth * 0.045,
                                              )),
                                          if (_hintActive)
                                            Text('${_hintSeconds}s',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize:
                                                    screenWidth * 0.03)),

                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: smallPadding,
                            ),
                            Visibility(
                              visible: true,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: SizedBox(
                                width: double.infinity,
                                height: screenHeight * 0.07,
                                child: ElevatedButton(
                                  onPressed: () {

                                  },
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
                              ),
                            ),
                          ],
                        ),
                      )
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
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: charUsed[charIdx]
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : GestureDetector(
                key: ValueKey('char_$charIdx'),
                onTap: () => _onCharTap(charIdx),
                child: Container(
                  margin: EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
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
                        color: Color(0xFF556B2F),
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
    rows.add(SizedBox(height: size * 0.1));
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
    if (words.length == 2) {
      for (var word in words) {
        List<Widget> row = List.generate(
            word.length, (i) => _buildAnswerBox(slotIdx++, slots, size));
        rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row)); // Đã xóa Padding ở đây
        rows.add(SizedBox(height: size * 0.1));

      }
      if (rows.isNotEmpty) rows.removeLast();
    } else if (words.length > 1) {
      List<Widget> currentRow = [];
      int currentLength = 0;
      for (int i = 0; i < words.length; i++) {
        int wordLen = words[i].length;
        if (currentLength + wordLen > maxCharsPerRow && currentRow.isNotEmpty) {
          rows.add(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: currentRow)); // Đã xóa Padding ở đây
          rows.add(SizedBox(height: size * 0.05));

          currentRow = [];
          currentLength = 0;
        }
        currentRow.addAll(List.generate(
            wordLen, (j) => _buildAnswerBox(slotIdx++, slots, size)));
        currentLength += wordLen;
        if (i < words.length - 1) {
          if (currentLength <= maxCharsPerRow) {
            currentRow.add(SizedBox(width: size * 0.1));
            currentLength += 1;
          } else {
            rows.add(Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: currentRow.map((widget) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.1),
                  child: widget,
                )).toList()));
            rows.add(SizedBox(height: size * 0.1));

            currentRow = [];
            currentLength = 0;
          }
        }
      }
      if (currentRow.isNotEmpty) {
        rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: currentRow.map((widget) => Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.1),
              child: widget,
            )).toList()));
      }
    } else {
      String currentWord = words[0];
      if (currentWord.length <= maxCharsPerRow) {
        List<Widget> currentRow = List.generate(
            currentWord.length, (i) => _buildAnswerBox(slotIdx++, slots, size));
        rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: currentRow.map((widget) => Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.1),
              child: widget,
            )).toList()));

      } else {
        for (int i = 0; i < currentWord.length; i += maxCharsPerRow) {
          int endIdx = (i + maxCharsPerRow < currentWord.length)
              ? i + maxCharsPerRow
              : currentWord.length;
          List<Widget> wordRow = List.generate(
              endIdx - i, (j) => _buildAnswerBox(slotIdx++, slots, size));
          rows.add(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: wordRow)); // Đã xóa Padding ở đây

          if (endIdx < currentWord.length) {
            rows.add(SizedBox(height: size * 0.1));
          }
        }
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
          double offset = (isCorrect || isWrong) ? 10 * sin(_shakeAnimation.value) : 0;
          BoxDecoration boxDecoration;
          Color textColor = const Color(0xFF556B2F);
          Color boxColor; // Declare boxColor here

          if (isCorrect) {
            boxDecoration = BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Correct.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(8),
            );
            textColor = Colors.white;
            boxColor = Colors.transparent; // Assuming transparent for image background
          } else if (isWrong) {
            boxDecoration = BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Incorrect.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(8),
            );
            textColor = Colors.white;
            boxColor = Colors.transparent; // Assuming transparent for image background
          } else {
            // This is the default state for the answer box
            boxDecoration = BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 2), // Border here is correct
              borderRadius: BorderRadius.circular(8),
            );
            textColor = const Color(0xFF556B2F);
            boxColor = Colors.white; // Default color
          }

          return Transform.translate(
            offset: Offset(offset, 0),
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              margin: EdgeInsets.all(1.2),
              decoration: boxDecoration,
              alignment: Alignment.center,
              child: slots[slotIdx].isNotEmpty
                  ? Text(
                slots[slotIdx],
                key: ValueKey('answer_${slotIdx}_${slots[slotIdx]}'),
                style: TextStyle(
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              )
                  : const SizedBox.shrink(key: ValueKey('empty_answer')),

            ),
          );
        },
      ),
    );
  }
}