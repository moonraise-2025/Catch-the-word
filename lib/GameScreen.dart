import 'package:flutter/material.dart'; //giải thích: Thư viện giao diện người dùng Flutter
import 'dart:math'; //giải thích: Thư viện toán học, dùng cho random
import 'PopupAnswerCorrect.dart'; //giải thích: Import widget popup trả lời đúng

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
  int currentQuestion = 0; //giải thích: Chỉ số câu hỏi hiện tại
  int level = 1; //giải thích: Level hiện tại
  int diamonds = 0; //giải thích: Số kim cương hiện có

  late List<String> answerSlots; //giải thích: Danh sách ký tự đã điền vào đáp án
  late List<String> charOptions; //giải thích: Danh sách ký tự lựa chọn bên dưới
  late List<bool> charUsed; //giải thích: Trạng thái đã chọn của từng ký tự
  int currentSlot = 0; //giải thích: Vị trí ô đáp án hiện tại
  bool isCorrect = false; //giải thích: Trạng thái đúng/sai của đáp án

  late AnimationController _controller; //giải thích: Điều khiển animation cho hiệu ứng
  late Animation<double> _scaleAnimation; //giải thích: Animation phóng to/thu nhỏ
  late Animation<double> _fadeAnimation; //giải thích: Animation mờ dần
  late AnimationController _shakeController; //giải thích: Điều khiển animation lắc khi trả lời sai
  late Animation<double> _shakeAnimation; //giải thích: Animation lắc
  bool isWrong = false; //giải thích: Trạng thái trả lời sai
  late final int maxAnswerLength; //giải thích: Độ dài đáp án dài nhất trong tất cả câu hỏi

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
    _initAnimations(); //giải thích: Khởi tạo các animation
    _initGame(); //giải thích: Khởi tạo dữ liệu game cho câu hỏi đầu tiên
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

  void _onCharTap(int idx) { //giải thích: Xử lý khi người chơi chọn một ký tự
    if (currentSlot < answerSlots.length && !charUsed[idx]) {
      setState(() {
        answerSlots[currentSlot] = charOptions[idx]; //giải thích: Gán ký tự vào ô đáp án
        charUsed[idx] = true; //giải thích: Đánh dấu ký tự đã dùng
        currentSlot++;
        if (currentSlot == answerSlots.length) { //giải thích: Nếu đã điền hết đáp án
          String userAnswer = answerSlots.join('');
          isCorrect = userAnswer == questions[currentQuestion].answer.toUpperCase(); //giải thích: Kiểm tra đúng/sai
          if (isCorrect) {
            Future.delayed(const Duration(milliseconds: 300), showCorrectDialog); //giải thích: Hiện popup đúng sau 0.3s
          } else {
            setState(() {
              isWrong = true; //giải thích: Đánh dấu trả lời sai để chạy animation lắc
            });
            _shakeController.forward(from: 0); //giải thích: Chạy animation lắc
            Future.delayed(const Duration(seconds: 2), () {
              setState(() {
                isWrong = false;
                final answer = questions[currentQuestion].answer.toUpperCase();
                answerSlots = List.filled(answer.length, '');
                charOptions = _generateCharOptions(answer);
                charUsed = List.filled(charOptions.length, false);
                currentSlot = 0;
                isCorrect = false;
              });
            });
          }
        }
      });
    }
  }

  void _onAnswerSlotTap(int slotIndex) { //giải thích: Xử lý khi bấm vào ô đáp án để xóa ký tự
    if (answerSlots[slotIndex].isNotEmpty) {
      setState(() {
        String char = answerSlots[slotIndex];
        int idx = charOptions.indexOf(char);
        if (idx != -1) {
          charUsed[idx] = false; //giải thích: Đánh dấu ký tự chưa dùng
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
      // Always fill to maxRowLength
      return rowChildren;
    }

    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
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
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 60), // Icon gợi ý
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
                    return Column(
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
                        // Banner ads (no gap)
                        Container(
                          width: imageContainerSize, // Banner ads cùng chiều rộng với ảnh
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(vertical: 16), //giải thích: Padding trên dưới cho banner
                          color: Colors.grey.shade200, // Màu nền banner ads
                          alignment: Alignment.center, // Căn giữa chữ
                          child: const Text(
                            'Banner ads', // Text banner ads (có thể thay bằng gợi ý)
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ),
                        // Answer grid
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
                      onPressed: () {}, //giải thích: Nút hiện đáp án (chưa có chức năng)
                      icon: const Icon(Icons.key_outlined),
                      label: const Text("Hiện đáp án"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        fixedSize: const Size(170, 70),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {}, //giải thích: Nút hỏi bạn bè (chưa có chức năng)
                      icon: const Icon(Icons.share_outlined),
                      label: const Text("Hỏi bạn bè"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        fixedSize: const Size(170, 70),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {}, //giải thích: Nút gợi ý (chưa có chức năng)
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text("Gợi ý"),
                                  style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        fixedSize: const Size(170, 70),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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