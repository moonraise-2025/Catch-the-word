import 'package:duoihinhbatchu/GiftPopup.dart';
import 'package:flutter/material.dart'; // thư viện giao diện người dùng của Flutter để sử dụng thành phần có sẵn
import 'dart:math'; // để sử dụng các hàm toán học trong Flutter
import 'PopupAnswerCorrect.dart';
import 'package:shared_preferences/shared_preferences.dart'; // để lưu trữ local
import 'package:intl/intl.dart';

class Question {
  // lớp câu hỏi và câu trả lời
  final String imageName; // tên file ảnh
  final String answer; // câu trả lời
  Question(
      {required this.imageName,
      required this.answer}); // yêu cầu cần có tên file ảnh và câu trả lời của ảnh đó
}

class GameScreen extends StatefulWidget {
  // tạo một màn hình game kế thừa thuộc  tính của StatefulWidget, kế thừa để cập nhật được các thay đổi giao diện khi dữ liệu thay đổi
  // không kế thừa thì không dùng setState() -> game sẽ chạy không như mong muốn
  const GameScreen(
      {super.key}); // hàm khởi tạo cho class GameScreen, truyền cây cho lớp cha(StatefulWidget) để biết khi nào thay đổi trong cây wibget

  @override
  State<GameScreen> createState() =>
      _GameScreenState(); // bắt buộc phải có khi tạo một StatefulWidget để quản lý trạng thái xây dựng giao diện
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // trộn vào SingleTickerProviderStateMixin để quản lý animation là Ticker, SingleTickerProviderStateMixin cho phép animation controller hoạt động bằng cách cung cấp ticker - cơ chế này giúp Flutter biết khi nào cần cập nhật giao diện
  final List<Question> questions = [
    // danh sách các câu hỏi và câu trả lời của từng câu
    Question(imageName: 'cau1.png', answer: 'CƯỚPBIỂN'),
    Question(imageName: 'cau2.png', answer: 'THUỶTINH'),
    //Question(imageName: 'cau3.png', answer: 'GIẤUĐẦULÒIĐUÔI'),
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

  int currentQuestion = 0; // khai báo câu hỏi hiện tại
  int level = 1; // khai báo cấp độ đầu tiên
  int diamonds = 0; // khai báo số kim cương ban đầu

  late List<String>
      answerSlots; // khai báo biến danh sách các đáp án - sẽ khởi tạo sau
  late List<String>
      charOptions; // khai báo biến danh sách các ký tự lựa chọn - sẽ khởi tạo sau, không khởi tạo ngay khi khai báo
  late List<bool>
      charUsed; // khai báo biến danh sách các ký tự đã được chọn - sẽ khởi tạo sau
  int currentSlot = 0; // khai báo vị trí hiện tại của đáp án
  bool isCorrect =
      false; // khai báo biến kiểm tra đúng sai - để mặc định là false

  late AnimationController
      _controller; // khai báo animation controller - khởi tạo sau  - dùng để quản lý lặp, dừng, chạy của animation
  late Animation<double>
      _scaleAnimation; // khai báo biến animation scale - khởi tạo sau - dùng để thay đổi kích thước của một widget
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool isWrong = false;

  // khai báo biến animation fade - khởi tạo sau - dùng để thay đổi độ mờ/độ trong suốt của một widget

  @override
  void initState() {
    // khởi tạo các biến, hàm chạy đầu tiên khi khởi tạo màn hình
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // gọi hàm gốc để đảm bảo Flutter hoạt động bình thường
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      // nhanh hơn và lắc nhiều lần
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 8 * 3.1415926535).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );

    _initAnimations(); // hàm khởi tại các animation
    _initGame(); // hàm khởi tạo game - VD: câu hỏi, đáp án, trạng thái,...

    checkAndResetDailyProgress(); //reset nhiệm vụ nếu sang ngày

  }

  void _initAnimations() {
    // khởi tạo các animation
    // _controller = AnimationController( // khởi tạo animation controller
    //   duration: const Duration(milliseconds: 300), // khởi tạo animation - để thiết lập thời gian chạy của animation với thời gian 300ms
    //   vsync: this, // đồng bộ các animation với tốc độ vẽ khung hình của từng thiết bị - giúp animation mượt hơn và tiết kiệm tài nguyên
    // );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      // khởi tạo animation scale - để thay đổi kích thước của một widget bằng cách dùng Tween<double> kết hợp với AnimationController để chạy theo thời gian quy định
      CurvedAnimation(
          parent: _controller,
          curve: Curves
              .easeOutBack), // bọc AnimationController bằng đường cong chuyển đổi "curve" để tạo hiệu ứng mượt và tự nhiên hơn
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      // khởi tạo animation fade - để chuyển từ ẩn từ hoàn toàn thành hiện hoàn toàn
      CurvedAnimation(
          parent: _controller,
          curve: Curves
              .easeIn), // làm hiệu ứng chạy mượt hơn, chạy chậm ở đầu và nhanh hơn ở cuối
    );

    _controller
        .forward(); // lệnh bắt đầu chạy animation do _controller điều khiển - chạy từ giá trị 0.0 đến 1.0 theo như duration và curve đã định nghĩa
  }

  @override
  void dispose() {
    // hàm huỷ của State - để giải phóng tài nguyên không còn sử dụng nữa
    _controller.dispose(); // huỷ AnimationController để tránh rò rỉ bộ nhớ
    _shakeController.dispose();
    super
        .dispose(); // gọi hàm dispose mặc định của Flutter để thực hiện các thao tác dọn dẹp khác
  }

  void _initGame() {
    //khởi tạo dữ liệu Game
    final answer = questions[currentQuestion]
        .answer
        .toUpperCase(); // để lấy đáp án của câu hỏi hiện tại và chuyển về chữ hoa
    answerSlots = List.filled(answer.length,
        ''); // khởi tạo các ô trong để người chơi điền từ vào ở phần đáp án
    charOptions = _generateCharOptions(
        answer); // tạo danh sách ký tự lựa chọn cho đáp án hiện tại
    charUsed = List.filled(charOptions.length,
        false); // khởi tạo danh sách trạng thái đã chọn cho từng ký tự ban đầu tất cả là false
    currentSlot = 0; // đặt lại vị trí ô đáp án hiện tại về 0
    isCorrect = false; // đặt lại trạng thái đúng sai về false
    _controller.reset(); // đặt lại animation controller về trạng thái ban đầu
    _controller.forward(); // bắt đầu chạy animation
  }

  List<String> _generateCharOptions(String answer) {
    // tạo danh sách ký tự lựa chọn gồm đáp án và ký tự gây nhiễu
    const String alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; // bảng chữ cái tiếng Anh để lấy ký tự gây nhiễu
    List<String> chars =
        answer.split(''); // tách đáp án thành từng ký tự riêng lẻ
    Random rnd = Random(); // tạo đối tượng random để sinh số ngẫu nhiên

    // Tính số lượng chữ gây nhiễu dựa vào độ dài đáp án
    int numDistractors; // biến lưu số lượng ký tự gây nhiễu cần thêm
    if (answer.length <= 5) {
      // nếu đáp án ngắn hơn hoặc bằng 5 ký tự
      numDistractors =
          2 + rnd.nextInt(2); // random 2 hoặc 3 ký tự gây nhiễu ngẫu nhiên
    } else if (answer.length <= 10) {
      // nếu đáp án từ 6 đến 10 ký tự
      numDistractors =
          4 + rnd.nextInt(2); // random 4 hoặc 5 ký tự gây nhiễu ngẫu nhiên
    } else {
      // nếu đáp án dài hơn 10 ký tự
      if (answer.length < 16) {
        // nếu tổng số ký tự chưa đủ 16
        numDistractors = 16 - answer.length; // thêm cho đủ 16 ký tự
      } else {
        // nếu đã đủ hoặc hơn 16 ký tự
        numDistractors = 1 + rnd.nextInt(2); // random 1 hoặc 2 ký tự gây nhiễu
      }
    }

    while (chars.length < answer.length + numDistractors) {
      // số lượng ký tự trong đáp án và số lượng chữ nhiễu cần thêm
      String c = alphabet[rnd
          .nextInt(alphabet.length)]; // lấy ngẫu nhiên 1 chữ từ biến alphabet
      if (!answer.contains(c)) {
        // chỉ thêm chữ vào chars nếu nó không nằm trong đáp án
        chars.add(c);
      }
    }
    chars.shuffle(); // trộn ngẫu nhiên các chữ trong danh sách chars
    return chars; // trả về chars
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
        answerSlots[slotIndex] = ''; // xoá ký tự khỏi ô
        currentSlot = slotIndex; // đặt lại vị trí ô hiện tại
        isCorrect = false; // đặt lại trạng thái đúng sai
      });
    }
  }

  void showCorrectDialog() {
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


  @override
  Widget build(BuildContext context) {
    // hàm xây dựng giao diện màn hình game
    final question = questions[currentQuestion]; // lấy câu hỏi hiện tại
    final screenWidth =
        MediaQuery.of(context).size.width; // lấy chiều rộng màn hình
    final screenHeight =
        MediaQuery.of(context).size.height; // lấy chiều cao màn hình

    final double imageContainerSize =
        screenWidth * 0.4; // kích thước khung ảnh là 40% chiều rộng màn hình
    final double answerBoxSize =
        screenWidth * 0.09; // kích thước mỗi ô đáp án là 9% chiều rộng màn hình
    final double smallPadding = screenWidth * 0.01; // padding nhỏ
    final double mediumPadding = screenWidth * 0.02; // padding vừa
    final double largePadding = screenWidth * 0.08; // padding lớn
    final double fontSizeAnswer = screenWidth * 0.055; // cỡ chữ đáp án
    final double fontSizeChar = screenWidth * 0.055; // cỡ chữ ký tự

    return Scaffold(
      // khung giao diện chính
      body: Container(
        // nền chính
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background2.png'), // ảnh nền
            fit: BoxFit.cover, // phủ kín
            repeat: ImageRepeat.noRepeat, // không lặp lại
          ),
        ),
        child: SafeArea(
          // đảm bảo không bị che bởi tai thỏ viền màn hình
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: mediumPadding, vertical: smallPadding),
                // padding cho header
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          size: 32, color: Colors.white),
                      // nút quay lại
                      onPressed: () =>
                          Navigator.pop(context), // quay lại màn hình trước
                    ),
                    SizedBox(width: smallPadding), // khoảng cách
                    Expanded(
                      child: Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation, // hiệu ứng phóng to thu nhỏ
                          child: FadeTransition(
                            opacity: _fadeAnimation, // hiệu ứng mờ dần
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              // chiều ngang vừa đủ
                              children: [
                                const Text('Level ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 50)),
                                // text level
                                Text('$level',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 50)),
                                // hiển thị level hiện tại
                                SizedBox(width: largePadding),
                                // khoảng cách
                                Icon(Icons.diamond,
                                    color: Colors.blueAccent, size: 60),
                                // icon kim cương
                                SizedBox(width: smallPadding),
                                // khoảng cách
                                Text('$diamonds',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 50)),
                                // hiển thị số kim cương
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

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // căn giữa theo chiều dọc
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation, // hiệu ứng phóng to thu nhỏ cho ảnh
                    child: FadeTransition(
                      opacity: _fadeAnimation, // hiệu ứng mờ dần cho ảnh
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.12,
                            screenHeight * 0.3,
                            screenWidth * 0.12,
                            screenWidth * 0.05),
                        // padding cho ảnh
                        child: Container(
                          width: imageContainerSize, // kích thước khung ảnh
                          height: imageContainerSize,
                          decoration: BoxDecoration(
                            color: Colors.white, // nền trắng cho khung ảnh
                            border: Border.all(
                                color: Colors.black26), // viền xám nhạt
                          ),
                          child: Image.asset(
                            'assets/questions/${question.imageName}',
                            // ảnh câu hỏi
                            fit: BoxFit.contain, // hiển thị vừa khung
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                  'Error loading image: $error'); // in lỗi nếu không tải được ảnh
                              return const Center(
                                child: Text(
                                  'Không thể tải ảnh', // thông báo lỗi
                                  style: TextStyle(color: Colors.red), // màu đỏ
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    // hiệu ứng phóng to thu nhỏ cho đáp án
                    child: FadeTransition(
                      opacity: _fadeAnimation, // hiệu ứng mờ dần cho đáp án
                      child: Container(
                        margin: EdgeInsets.only(top: screenHeight * 0.03),
                        // khoảng cách phía trên đáp án
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          // căn giữa đáp án
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  // căn giữa hàng 1 đáp án
                                  children: [
                                    for (int i = 0;
                                        i < (answerSlots.length + 1) ~/ 2;
                                        i++) // lặp qua nửa đầu các ô đáp án
                                      GestureDetector(
                                        onTap: () => _onAnswerSlotTap(i),
                                        // xoá ký tự khi bấm vào ô
                                        child: Container(
                                          width: answerBoxSize,
                                          // kích thước ô đáp án
                                          height: answerBoxSize,
                                          margin: EdgeInsets.symmetric(
                                              horizontal: smallPadding / 2),
                                          // khoảng cách giữa các ô
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black, width: 2),
                                            // viền đen
                                            color: Colors.white, // nền trắng
                                          ),
                                          alignment: Alignment.center,
                                          // căn giữa ký tự
                                          child: AnimatedBuilder(
                                            animation: _shakeController,
                                            builder: (context, child) {
                                              return Transform.rotate(
                                                angle: isWrong
                                                    ? 0.25 *
                                                        (i.isEven ? 1 : -1) *
                                                        (sin(_shakeAnimation
                                                            .value))
                                                    : 0,
                                                child: child,
                                              );
                                            },
                                            child: Text(
                                              answerSlots[i],
                                              // ký tự trong ô đáp án
                                              style: TextStyle(
                                                fontSize: fontSizeAnswer,
                                                // cỡ chữ đáp án
                                                fontWeight: FontWeight.bold,
                                                // chữ đậm
                                                color: currentSlot ==
                                                        answerSlots.length
                                                    ? (isCorrect
                                                        ? Colors.green
                                                        : Colors.red)
                                                    : Colors
                                                        .black, // màu xanh nếu đúng đỏ nếu sai mặc định đen
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: smallPadding),
                                // khoảng cách giữa 2 hàng đáp án
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  // căn giữa hàng 2 đáp án
                                  children: [
                                    for (int i = (answerSlots.length + 1) ~/ 2;
                                        i < answerSlots.length;
                                        i++) // lặp qua nửa sau các ô đáp án
                                      GestureDetector(
                                        onTap: () => _onAnswerSlotTap(i),
                                        // xoá ký tự khi bấm vào ô
                                        child: Container(
                                          width: answerBoxSize,
                                          // kích thước ô đáp án
                                          height: answerBoxSize,
                                          margin: EdgeInsets.symmetric(
                                              horizontal: smallPadding / 2),
                                          // khoảng cách giữa các ô
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black, width: 2),
                                            // viền đen
                                            color: Colors.white, // nền trắng
                                          ),
                                          alignment: Alignment.center,
                                          // căn giữa ký tự
                                          child: AnimatedBuilder(
                                            animation: _shakeController,
                                            builder: (context, child) {
                                              return Transform.rotate(
                                                angle: isWrong
                                                    ? 0.25 *
                                                        (i.isEven ? 1 : -1) *
                                                        (sin(_shakeAnimation
                                                            .value))
                                                    : 0,
                                                child: child,
                                              );
                                            },
                                            child: Text(
                                              answerSlots[i],
                                              // ký tự trong ô đáp án
                                              style: TextStyle(
                                                fontSize: fontSizeAnswer,
                                                // cỡ chữ đáp án
                                                fontWeight: FontWeight.bold,
                                                // chữ đậm
                                                color: currentSlot ==
                                                        answerSlots.length
                                                    ? (isCorrect
                                                        ? Colors.green
                                                        : Colors.red)
                                                    : Colors
                                                        .black, // màu xanh nếu đúng đỏ nếu sai mặc định đen
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(width: mediumPadding),
                            // khoảng cách bên phải đáp án
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(), // đẩy các nút ký tự xuống cuối

              LayoutBuilder(
                builder: (context, constraints) {
                  // Số ô tối đa trên một hàng
                  int maxRowLength = ((charOptions.length + 1) / 2).ceil();
                  // Tính lại kích thước ô cho vừa vùng chứa
                  double dynamicCharButtonSize = (constraints.maxWidth -
                          smallPadding * (maxRowLength - 1)) /
                      maxRowLength;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < maxRowLength; i++) ...[
                            if (i > 0) SizedBox(width: smallPadding),
                            i < charOptions.length
                                ? (charUsed[i]
                                    ? SizedBox(
                                        width: dynamicCharButtonSize,
                                        height: dynamicCharButtonSize)
                                    : ElevatedButton(
                                        onPressed: () => _onCharTap(i),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(
                                              dynamicCharButtonSize,
                                              dynamicCharButtonSize),
                                          backgroundColor: Colors.purpleAccent,
                                        ),
                                        child: Text(
                                          charOptions[i],
                                          style: TextStyle(
                                              fontSize: fontSizeChar,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ))
                                : SizedBox(
                                    width: dynamicCharButtonSize,
                                    height: dynamicCharButtonSize),
                          ],
                        ],
                      ),
                      if (charOptions.length > maxRowLength)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = maxRowLength;
                                i < maxRowLength * 2;
                                i++) ...[
                              if (i > maxRowLength)
                                SizedBox(width: smallPadding),
                              i < charOptions.length
                                  ? (charUsed[i]
                                      ? SizedBox(
                                          width: dynamicCharButtonSize,
                                          height: dynamicCharButtonSize)
                                      : ElevatedButton(
                                          onPressed: () => _onCharTap(i),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(
                                                dynamicCharButtonSize,
                                                dynamicCharButtonSize),
                                            backgroundColor:
                                                Colors.purpleAccent,
                                          ),
                                          child: Text(
                                            charOptions[i],
                                            style: TextStyle(
                                                fontSize: fontSizeChar,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ))
                                  : SizedBox(
                                      width: dynamicCharButtonSize,
                                      height: dynamicCharButtonSize),
                            ],
                          ],
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: mediumPadding), // khoảng cách dưới cùng
            ],
          ),
        ),
      ),
    );
  }
}
