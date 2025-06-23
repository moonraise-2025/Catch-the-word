
import 'package:flutter/material.dart'; //giải thích: Thư viện giao diện người dùng Flutter
import 'package:flutter/rendering.dart';
import 'dart:math'; //giải thích: Thư viện toán học, dùng cho random
import 'PopupAnswerCorrect.dart';
import 'PopupWatchVideo.dart'; //giải thích: Import widget popup trả lời đúng
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:duoihinhbatchu/GiftPopup.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // để lưu trữ local
import 'package:intl/intl.dart';

class Question { //giải thích: Lớp đại diện cho một câu hỏi
  final String imageName; //giải thích: Tên file ảnh câu hỏi
  final String answer; //giải thích: Đáp án của câu hỏi
  Question({required this.imageName, required this.answer}); //giải thích: Hàm khởi tạo, bắt buộc có tên ảnh và đáp án
}

class GameScreen extends StatefulWidget { //giải thích: Widget màn hình game, có trạng thái
  const GameScreen({super.key}); //giải thích: Hàm khởi tạo, truyền key cho widget cha

  @override
  State<GameScreen> createState() => _GameScreenState(); //giải thích: Tạo state cho widget
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin { //giải thích: State của GameScreen, quản lý trạng thái và animation
  final List<Question> questions = [ //giải thích: Danh sách các câu hỏi và đáp án
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
    //Question(imageName: 'cau17.png', answer: 'CHẠYNƯỚCRÚT'),
    Question(imageName: 'cau18.png', answer: 'TAYCHÂN'),
  ];
  
  int dailyCount = 0; //  Biến đếm nhiệm vụ ngày
  int daily30Count = 0; //  Biến đếm nhiệm vụ tuần: 30 câu
  int daily50Count = 0; //  Biến đếm nhiệm vụ tuần: 50 câu

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

  late AnimationController _controller; //giải thích: Điều khiển animation cho hiệu ứng
  late Animation<double> _scaleAnimation; //giải thích: Animation phóng to/thu nhỏ
  late Animation<double> _fadeAnimation; //giải thích: Animation mờ dần
  late AnimationController _shakeController; //giải thích: Điều khiển animation lắc khi trả lời sai
  late Animation<double> _shakeAnimation; //giải thích: Animation lắc
  bool isWrong = false; //giải thích: Trạng thái trả lời sai
  late final int maxAnswerLength; //giải thích: Độ dài đáp án dài nhất trong tất cả câu hỏi

  final GlobalKey previewContainerKey = GlobalKey();
  Future<void> captureAndShareWidget() async {
    try {
      RenderRepaintBoundary boundary = previewContainerKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
        return captureAndShareWidget(); // đợi render xong
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
  void initState() { //giải thích: Hàm khởi tạo state, chạy đầu tiên khi mở màn hình
    super.initState();
    maxAnswerLength = questions.map((q) => q.answer.length).reduce((a, b) => a > b ? a : b); //giải thích: Tìm độ dài đáp án lớn nhất
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

    _initAnimations(); // hàm khởi tại các animation
    _initGame(); // hàm khởi tạo game - VD: câu hỏi, đáp án, trạng thái,...

    checkAndResetDailyProgress(); //reset nhiệm vụ nếu sang ngày


  }

  void _initAnimations() { //giải thích: Khởi tạo các animation cho hiệu ứng
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward(); //giải thích: Bắt đầu chạy animation
  }

  @override
  void dispose() { //giải thích: Hủy các controller khi không dùng nữa để tránh rò rỉ bộ nhớ
    _controller.dispose();
    _shakeController.dispose(); 
    _hintTimer?.cancel();
    super.dispose();
  }

  void _initGame() { //giải thích: Khởi tạo lại dữ liệu cho mỗi câu hỏi mới
    final answer = questions[currentQuestion].answer.toUpperCase(); //giải thích: Lấy đáp án hiện tại, chuyển thành chữ hoa
    answerSlots = List.filled(answer.length, ''); //giải thích: Tạo các ô trống cho đáp án
    charOptions = _generateCharOptions(answer); //giải thích: Sinh ra các ký tự lựa chọn (bao gồm cả ký tự gây nhiễu)
    charUsed = List.filled(charOptions.length, false); //giải thích: Đánh dấu tất cả ký tự chưa được chọn
    currentSlot = 0; //giải thích: Đặt lại vị trí ô đáp án hiện tại
    isCorrect = false; //giải thích: Đặt lại trạng thái đúng/sai
    _controller.reset(); //giải thích: Reset animation
    _controller.forward(); //giải thích: Chạy lại animation
    _hintBanner = null;
    _hintUsedOnce = false;
    _startHintCountdown(); // Bắt đầu đếm ngược 20s mỗi khi vào câu mới
  }

  List<String> _generateCharOptions(String answer) { //giải thích: Sinh ra danh sách ký tự lựa chọn cho đáp án
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; //giải thích: Bảng chữ cái tiếng Anh
    List<String> chars = answer.split(''); //giải thích: Tách đáp án thành từng ký tự
    Random rnd = Random(); //giải thích: Đối tượng random
    int numDistractors; //giải thích: Số ký tự gây nhiễu cần thêm
    if (answer.length <= 5) {
      numDistractors = 5 + rnd.nextInt(6); //giải thích: Nếu đáp án ngắn, thêm nhiều ký tự gây nhiễu
    } else if (answer.length <= 10) {
      numDistractors = 4 + rnd.nextInt(2); //giải thích: Đáp án vừa, thêm ít ký tự gây nhiễu hơn
    } else {
      if (answer.length < 16) {
        numDistractors = 16 - answer.length; //giải thích: Đảm bảo tổng số ký tự là 16
      } else {
        numDistractors = 1 + rnd.nextInt(2); //giải thích: Đáp án dài, chỉ thêm 1-2 ký tự gây nhiễu
      }
    }
    while (chars.length < answer.length + numDistractors) { //giải thích: Thêm ký tự gây nhiễu cho đủ số lượng
      String c = alphabet[rnd.nextInt(alphabet.length)];
      if (!answer.contains(c)) {
        chars.add(c); 
      }
    }
    chars.shuffle(); //giải thích: Trộn ngẫu nhiên các ký tự
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
          // ✅ Delay nhẹ để hiển thị hiệu ứng đúng
          Future.delayed(const Duration(milliseconds: 300), showCorrectDialog);

          // ✅ Cập nhật các biến nhiệm vụ (ngoài setState để tối ưu)
          if (dailyCount < 1) dailyCount++;
          if (daily30Count < 30) daily30Count++;
          if (daily50Count < 50) daily50Count++;;

          // ✅ Lưu vào SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('dailyCount', dailyCount);
          await prefs.setInt('daily30Count', daily30Count);
          await prefs.setInt('daily50Count', daily50Count);
        } else {
          // ❌ Trả lời sai
          setState(() {
            isWrong = true;
          });

          _shakeController.forward(from: 0); // hiệu ứng rung

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
    // hàm xử lý khi bấm vào ô đáp án để xoá ký tự
    if (answerSlots[slotIndex].isNotEmpty) {
      // chỉ xoá nếu ô có ký tự
      setState(() {
        // cập nhật lại giao diện
        String char = answerSlots[slotIndex]; // lấy ký tự trong ô
        int idx = charOptions
            .indexOf(char); // tìm vị trí ký tự trong danh sách lựa chọn
        if (idx != -1) {
          // nếu tìm thấy
          charUsed[idx] = false; // đánh dấu ký tự chưa dùng
        }
        answerSlots[slotIndex] = '';
        currentSlot = slotIndex;
        isCorrect = false;
      });
    }
  }

  void showCorrectDialog() { //giải thích: Hiện popup trả lời đúng
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopupAnswerCorrect(
          onNext: () {
            Navigator.of(context).pop();
            setState(() {
              if (currentQuestion < questions.length - 1) {
                currentQuestion++;
                level++;
                diamonds += 5;

                // if (dailyCount < 1) dailyCount++;         //  Nhiệm vụ ngày: chỉ cần đúng 1 câu
                // if (daily30Count < 30) weekly30Count++;  //  Nhiệm vụ tuần 1: đúng tối đa 30 câu
                // if (daily50Count < 50) weekly50Count++;  //  Nhiệm vụ tuần 2: đúng tối đa 50 câu

                _initGame();
              } else {
                currentQuestion = 0;
                level = 1;
                diamonds = 0;
                _initGame();
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
      // 👉 Sang ngày mới: reset nhiệm vụ
      await prefs.setInt('dailyCount', 0);
      await prefs.setInt('daily30Count', 0);
      await prefs.setInt('daily50Count', 0);
      await prefs.setBool('dailyRewarded', false);
      await prefs.setBool('daily30Rewarded', false);
      await prefs.setBool('daily50Rewarded', false);
      await prefs.setString('lastRewardDate', todayStr);
    }

    // 👉 Cập nhật lại biến khi khởi tạo màn chơi
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
        // Trừ kim cương
        diamonds -= 10;
        // Tìm ô trống đầu tiên
        final answer = questions[currentQuestion].answer.toUpperCase();
        for (int i = 0; i < answerSlots.length; i++) {
          if (answerSlots[i].isEmpty) {
            String correctChar = answer[i];
            // Tìm vị trí ký tự đúng trong charOptions chưa dùng
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
    int revealCount = answer.length >= 4 ? 4 : answer.length;
    String hint = answer.substring(0, revealCount);
    setState(() {
      _hintBanner = hint;
      _hintUsedOnce = true;
    });
  }

  @override

  Widget build(BuildContext context) { //giải thích: Xây dựng giao diện màn hình game
    final question = questions[currentQuestion]; //giải thích: Lấy câu hỏi hiện tại
    final screenWidth = MediaQuery.of(context).size.width; //giải thích: Lấy chiều rộng màn hình
    final screenHeight = MediaQuery.of(context).size.height; //giải thích: Lấy chiều cao màn hình

    final double imageContainerSize = screenWidth * 0.4; //giải thích: Kích thước khung ảnh
    final double smallPadding = screenWidth * 0.02; //giải thích: Padding nhỏ
    final double mediumPadding = screenWidth * 0.02; //giải thích: Padding vừa
    final double largePadding = screenWidth * 0.08; //giải thích: Padding lớn
    final double fontSizeChar = screenWidth * 0.055; //giải thích: Cỡ chữ ký tự

    const int maxPerRow = 8; //giải thích: Số ô tối đa trên 1 hàng đáp án
    int row1Count = answerSlots.length > maxPerRow ? maxPerRow : answerSlots.length; //giải thích: Số ô hàng 1
    int row2Count = answerSlots.length > maxPerRow ? answerSlots.length - maxPerRow : 0; //giải thích: Số ô hàng 2

    Widget buildAnswerRow(int start, int count, double answerBoxSize, double fontSizeAnswer) {
      List<Widget> children = [];
      for (int i = 0; i < count; i++) {
        children.add(GestureDetector(
          onTap: () => _onAnswerSlotTap(start + i),
          child: Container(
            width: answerBoxSize,
            height: answerBoxSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                double offset = isWrong ? 10 * (sin(_shakeAnimation.value)) : 0;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Text(
                answerSlots[start + i],
                style: TextStyle(
                  fontSize: fontSizeAnswer,
                  fontWeight: FontWeight.bold,
                  color: currentSlot == answerSlots.length
                      ? (isCorrect ? Colors.green : Colors.red)
                      : Colors.black,
                ),
              ),
            ),
          ),
        ));
        if (i < count - 1) {
          children.add(SizedBox(width: 4));
        }
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    List<Widget> buildCharRow(int start, int end, double dynamicCharButtonSize) {
      List<Widget> rowChildren = [];
      for (int i = start; i < end; i++) {
        if (i > start) rowChildren.add(SizedBox(width: 4));
        if (i < charOptions.length) {
          rowChildren.add(
            charUsed[i]
                ? SizedBox(width: dynamicCharButtonSize, height: dynamicCharButtonSize)
                : ElevatedButton(
                    onPressed: () => _onCharTap(i),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(dynamicCharButtonSize, dynamicCharButtonSize),
                      backgroundColor: Colors.purpleAccent,
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
        ),

                    child: Text(
                      charOptions[i],
                      style: TextStyle(fontSize: dynamicCharButtonSize * 0.45, fontWeight: FontWeight.bold),
                    ),
                  )
          );
        } else {
          rowChildren.add(SizedBox(width: dynamicCharButtonSize, height: dynamicCharButtonSize));
        }
      }
      
      return rowChildren;
    }

    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(

                padding: EdgeInsets.symmetric(horizontal: mediumPadding, vertical: smallPadding), //giải thích: Header hiển thị level, kim cương, nút back
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 32, color: Colors.black), //giải thích: Nút quay lại
                      onPressed: () => Navigator.pop(context), //giải thích: Quay lại màn hình trước
                    ),
                    SizedBox(width: smallPadding), //giải thích: Khoảng cách
                    Expanded(
                      child: Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation, // Hiệu ứng phóng to
                          child: FadeTransition(
                            opacity: _fadeAnimation, // Hiệu ứng mờ dần
                            child: Row(

                              mainAxisSize: MainAxisSize.min, // Chiều ngang vừa đủ
                              children: [
                                const Text('Level ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50)), // Text level
                                Text('$level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)), // Hiển thị level hiện tại
                                SizedBox(width: largePadding), // Khoảng cách
                                Icon(Icons.diamond, color: Colors.blueAccent, size: 60), //giải thích: Icon kim cương
                                SizedBox(width: smallPadding), // Khoảng cách
                                Text('$diamonds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)), // Hiển thị số kim cương
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                   GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Giftpopup(
                            dailyCount: dailyCount,
                            daily30Count: daily30Count,
                            daily50Count: daily50Count,
                            onReward: (amount) {
                              setState(() {
                                diamonds += amount; // Cộng kim cương
                              });
                            },
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.pink,
                        size: 60,
                      ),
                    ),
                  ],
                ),
              ),

               Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int maxRowLength = 8;
                    double dynamicCharButtonSize = (constraints.maxWidth - smallPadding * (maxRowLength - 1) - mediumPadding * 2) / maxRowLength;
                    double answerBoxSize = dynamicCharButtonSize * 1.15;
                    double fontSizeAnswer = dynamicCharButtonSize * 0.45;

                    return RepaintBoundary(
                      key: previewContainerKey,
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Căn giữa dọc
                      crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa ngang
                      mainAxisSize: MainAxisSize.max,
                      children: [
                      ScaleTransition(
                      scale: _scaleAnimation, // Hiệu ứng phóng to cho ảnh
                      child: FadeTransition(
                        opacity: _fadeAnimation, // Hiệu ứng mờ dần cho ảnh
                        child: Container(
                          margin: EdgeInsets.only(top: screenHeight * 0.01, bottom: 0), //giải thích: Khoảng cách trên ảnh
                          width: imageContainerSize, // Kích thước ảnh
                          height: imageContainerSize,
                          decoration: BoxDecoration(
                            color: Colors.white, // Nền trắng cho khung ảnh
                            border: Border.all(color: Colors.black26), //Viền xám nhạt
                          ),
                          child: Image.asset(
                          'assets/questions/${question.imageName}', //Ảnh câu hỏi
                          fit: BoxFit.contain, // Hiển thị vừa khung
                          errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Không thể tải ảnh'));
                        },
                        ),
                      ),
                    ),
                    ),
                    Container(
                    width: imageContainerSize,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Text(
                    _hintBanner ?? 'Banner ads',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                    textAlign: TextAlign.center,
                    ),
                    ),
                    Padding(
                    padding: EdgeInsets.only(top: mediumPadding, bottom: smallPadding), // Padding trên/dưới đáp án
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, //Căn giữa đáp án
                    children: [
                    if (row1Count > 0) buildAnswerRow(0, row1Count, answerBoxSize, fontSizeAnswer), //giải thích: Hàng 1 đáp án
                    if (row2Count > 0) ...[
                    SizedBox(height: smallPadding), // Khoảng cách giữa 2 hàng đáp án
                    buildAnswerRow(maxPerRow, row2Count, answerBoxSize, fontSizeAnswer), //giải thích: Hàng 2 đáp án
                    ],
                    ],
                    ),
                    ),
                    Container(
                    padding: EdgeInsets.symmetric(horizontal: mediumPadding), // Padding ngang cho lưới ký tự
                    child: Column(
                    children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Căn giữa hàng ký tự
                    children: buildCharRow(0, maxRowLength, dynamicCharButtonSize),
                    ),
                    SizedBox(height: smallPadding),
                    Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: buildCharRow(maxRowLength, maxRowLength * 2, dynamicCharButtonSize),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),


              // Function buttons at the bottom

              Padding(
                padding: EdgeInsets.symmetric(horizontal: largePadding, vertical: mediumPadding), //giải thích: Padding cho các nút chức năng
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, //giải thích: Các nút cách đều nhau
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showRevealLetterDialog,
                      icon: const Icon(Icons.key_outlined),
                      label: const Text("Hiện đáp án"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        textStyle: const TextStyle(
                          fontSize: 22,              // chỉnh kích cỡ chữ
                          fontWeight: FontWeight.bold // in đậm
                        ),
                        fixedSize: const Size(220, 100),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: captureAndShareWidget,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text("Hỏi bạn bè"),
                                  style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        textStyle: const TextStyle(
                          fontSize: 22,              // chỉnh kích cỡ chữ
                          fontWeight: FontWeight.bold // in đậm
                        ),
                        fixedSize: const Size(220, 100),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),

                    ElevatedButton(
                      onPressed: (_hintActive || _hintUsedOnce) ? null : () {
                        _onHint();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        fixedSize: const Size(220, 100),
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Gợi ý', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (_hintActive)
                            Text('(${_hintSeconds}s)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mediumPadding), //giải thích: Khoảng cách dưới cùng
            ],
          ),
        ),
      ),
    );
  }
}
