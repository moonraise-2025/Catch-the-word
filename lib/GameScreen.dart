import 'package:flutter/material.dart'; // thư viện giao diện người dùng của Flutter để sử dụng thành phần có sẵn 
import 'dart:math'; // để sử dụng các hàm toán học trong Flutter
import 'PopupAnswerCorrect.dart';

class Question { // lớp câu hỏi và câu trả lời
  final String imageName; // tên file ảnh
  final String answer; // câu trả lời
  Question({required this.imageName, required this.answer}); // yêu cầu cần có tên file ảnh và câu trả lời của ảnh đó
}

class GameScreen extends StatefulWidget { // tạo một màn hình game kế thừa thuộc  tính của StatefulWidget, kế thừa để cập nhật được các thay đổi giao diện khi dữ liệu thay đổi
                                        // không kế thừa thì không dùng setState() -> game sẽ chạy không như mong muốn
  const GameScreen({super.key});  // hàm khởi tạo cho class GameScreen, truyền cây cho lớp cha(StatefulWidget) để biết khi nào thay đổi trong cây wibget

  @override
  State<GameScreen> createState() => _GameScreenState(); // bắt buộc phải có khi tạo một StatefulWidget để quản lý trạng thái xây dựng giao diện 
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin
 { // trộn vào SingleTickerProviderStateMixin để quản lý animation là Ticker, SingleTickerProviderStateMixin cho phép animation controller hoạt động bằng cách cung cấp ticker - cơ chế này giúp Flutter biết khi nào cần cập nhật giao diện 
  final List<Question> questions = [ // danh sách các câu hỏi và câu trả lời của từng câu
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
  int currentQuestion = 0; // khai báo câu hỏi hiện tại 
  int level = 1; // khai báo cấp độ đầu tiên
  int diamonds = 0; // khai báo số kim cương ban đầu

  late List<String> answerSlots; // khai báo biến danh sách các đáp án - sẽ khởi tạo sau
  late List<String> charOptions; // khai báo biến danh sách các ký tự lựa chọn - sẽ khởi tạo sau, không khởi tạo ngay khi khai báo
  late List<bool> charUsed; // khai báo biến danh sách các ký tự đã được chọn - sẽ khởi tạo sau
  int currentSlot = 0; // khai báo vị trí hiện tại của đáp án
  bool isCorrect = false; // khai báo biến kiểm tra đúng sai - để mặc định là false

  late AnimationController _controller; // khai báo animation controller - khởi tạo sau  - dùng để quản lý lặp, dừng, chạy của animation
  late Animation<double> _scaleAnimation; // khai báo biến animation scale - khởi tạo sau - dùng để thay đổi kích thước của một widget
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool isWrong = false;
  late final int maxAnswerLength;
 // khai báo biến animation fade - khởi tạo sau - dùng để thay đổi độ mờ/độ trong suốt của một widget

  @override
  void initState() { // khởi tạo các biến, hàm chạy đầu tiên khi khởi tạo màn hình
    super.initState();
    maxAnswerLength = questions.map((q) => q.answer.length).reduce((a, b) => a > b ? a : b);
    _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    );
     // gọi hàm gốc để đảm bảo Flutter hoạt động bình thường
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1200), // nhanh hơn và lắc nhiều lần
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 8 * 3.1415926535).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );

    _initAnimations(); // hàm khởi tại các animation 
    _initGame(); // hàm khởi tạo game - VD: câu hỏi, đáp án, trạng thái,...
  }

  void _initAnimations() { // khởi tạo các animation
    // _controller = AnimationController( // khởi tạo animation controller
    //   duration: const Duration(milliseconds: 300), // khởi tạo animation - để thiết lập thời gian chạy của animation với thời gian 300ms
    //   vsync: this, // đồng bộ các animation với tốc độ vẽ khung hình của từng thiết bị - giúp animation mượt hơn và tiết kiệm tài nguyên 
    // );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(  // khởi tạo animation scale - để thay đổi kích thước của một widget bằng cách dùng Tween<double> kết hợp với AnimationController để chạy theo thời gian quy định
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack), // bọc AnimationController bằng đường cong chuyển đổi "curve" để tạo hiệu ứng mượt và tự nhiên hơn
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate( // khởi tạo animation fade - để chuyển từ ẩn từ hoàn toàn thành hiện hoàn toàn
      CurvedAnimation(parent: _controller, curve: Curves.easeIn), // làm hiệu ứng chạy mượt hơn, chạy chậm ở đầu và nhanh hơn ở cuối
    );

    _controller.forward(); // lệnh bắt đầu chạy animation do _controller điều khiển - chạy từ giá trị 0.0 đến 1.0 theo như duration và curve đã định nghĩa 
  }

  @override
  void dispose() { // hàm huỷ của State - để giải phóng tài nguyên không còn sử dụng nữa 
    _controller.dispose(); // huỷ AnimationController để tránh rò rỉ bộ nhớ
    _shakeController.dispose(); 
    super.dispose(); // gọi hàm dispose mặc định của Flutter để thực hiện các thao tác dọn dẹp khác
  }

  void _initGame() { //khởi tạo dữ liệu Game
    final answer = questions[currentQuestion].answer.toUpperCase(); // để lấy đáp án của câu hỏi hiện tại và chuyển về chữ hoa 
    answerSlots = List.filled(answer.length, ''); // khởi tạo các ô trong để người chơi điền từ vào ở phần đáp án
    charOptions = _generateCharOptions(answer); // tạo danh sách ký tự lựa chọn cho đáp án hiện tại
    charUsed = List.filled(charOptions.length, false); // khởi tạo danh sách trạng thái đã chọn cho từng ký tự ban đầu tất cả là false
    currentSlot = 0; // đặt lại vị trí ô đáp án hiện tại về 0
    isCorrect = false; // đặt lại trạng thái đúng sai về false
    _controller.reset(); // đặt lại animation controller về trạng thái ban đầu
    _controller.forward(); // bắt đầu chạy animation
  }

  List<String> _generateCharOptions(String answer) { // tạo danh sách ký tự lựa chọn gồm đáp án và ký tự gây nhiễu
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; // bảng chữ cái tiếng Anh để lấy ký tự gây nhiễu
    List<String> chars = answer.split(''); // tách đáp án thành từng ký tự riêng lẻ
    Random rnd = Random(); // tạo đối tượng random để sinh số ngẫu nhiên
    
    // Tính số lượng chữ gây nhiễu dựa vào độ dài đáp án
    int numDistractors; // biến lưu số lượng ký tự gây nhiễu cần thêm
    if (answer.length <= 5) { // nếu đáp án ngắn hơn hoặc bằng 5 ký tự
      numDistractors = 5 + rnd.nextInt(6); // random 2 hoặc 3 ký tự gây nhiễu ngẫu nhiên
    } else if (answer.length <= 10) { // nếu đáp án từ 6 đến 10 ký tự
      numDistractors = 4 + rnd.nextInt(2); // random 4 hoặc 5 ký tự gây nhiễu ngẫu nhiên
    } else { // nếu đáp án dài hơn 10 ký tự
      if (answer.length < 16) { // nếu tổng số ký tự chưa đủ 16
        numDistractors = 16 - answer.length; // thêm cho đủ 16 ký tự
      } else { // nếu đã đủ hoặc hơn 16 ký tự
        numDistractors = 1 + rnd.nextInt(2); // random 1 hoặc 2 ký tự gây nhiễu
      }
    }

    while (chars.length < answer.length + numDistractors) { // số lượng ký tự trong đáp án và số lượng chữ nhiễu cần thêm
      String c = alphabet[rnd.nextInt(alphabet.length)]; // lấy ngẫu nhiên 1 chữ từ biến alphabet  
      if (!answer.contains(c)) { // chỉ thêm chữ vào chars nếu nó không nằm trong đáp án
        chars.add(c); 
      }
    }
    chars.shuffle(); // trộn ngẫu nhiên các chữ trong danh sách chars
    return chars; // trả về chars
  }

  void _onCharTap(int idx) { // hàm xử lý khi người chơi chọn một ký tự
    if (currentSlot < answerSlots.length && !charUsed[idx]) { // chỉ cho phép chọn nếu còn ô trống và ký tự chưa được dùng
      setState(() { // cập nhật lại giao diện
        answerSlots[currentSlot] = charOptions[idx]; // gán ký tự được chọn vào ô đáp án hiện tại
        charUsed[idx] = true; // đánh dấu ký tự này đã được sử dụng
        currentSlot++; // chuyển sang ô đáp án tiếp theo

        if (currentSlot == answerSlots.length) { // nếu đã điền hết các ô đáp án
          String userAnswer = answerSlots.join(''); // ghép các ký tự lại thành đáp án người chơi nhập
          isCorrect = userAnswer == questions[currentQuestion].answer.toUpperCase(); // kiểm tra đáp án đúng hay sai
          if (isCorrect) {
            Future.delayed(const Duration(milliseconds: 300), showCorrectDialog);
          } else {
            setState(() {
              isWrong = true;
            });

            _shakeController.forward(from: 0); // chạy hiệu ứng rung

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

  void _onAnswerSlotTap(int slotIndex) { // hàm xử lý khi bấm vào ô đáp án để xoá ký tự
    if (answerSlots[slotIndex].isNotEmpty) { // chỉ xoá nếu ô có ký tự
      setState(() { // cập nhật lại giao diện
        String char = answerSlots[slotIndex]; // lấy ký tự trong ô
        int idx = charOptions.indexOf(char); // tìm vị trí ký tự trong danh sách lựa chọn
        if (idx != -1) { // nếu tìm thấy
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
  Widget build(BuildContext context) { // hàm xây dựng giao diện màn hình game
    final question = questions[currentQuestion]; // lấy câu hỏi hiện tại
    final screenWidth = MediaQuery.of(context).size.width; // lấy chiều rộng màn hình
    final screenHeight = MediaQuery.of(context).size.height; // lấy chiều cao màn hình

    final double imageContainerSize = screenWidth * 0.4; // kích thước khung ảnh là 40% chiều rộng màn hình
    final double smallPadding = screenWidth * 0.02;
    final double answerBoxSize = (screenWidth - smallPadding * (maxAnswerLength - 1)) / (maxAnswerLength + 1);
    final double mediumPadding = screenWidth * 0.02; // padding vừa
    final double largePadding = screenWidth * 0.08; // padding lớn
    final double fontSizeAnswer = screenWidth * 0.055; // cỡ chữ đáp án
    final double fontSizeChar = screenWidth * 0.055; // cỡ chữ ký tự

    const int maxPerRow = 8; // Số ô tối đa trên 1 hàng, có thể điều chỉnh
    int row1Count = answerSlots.length > maxPerRow ? maxPerRow : answerSlots.length;
    int row2Count = answerSlots.length > maxPerRow ? answerSlots.length - maxPerRow : 0;

    Widget buildAnswerRow(int start, int count) {
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
                return Transform.rotate(
                  angle: isWrong ? 0.25 * ((start + i).isEven ? 1 : -1) * (sin(_shakeAnimation.value)) : 0,
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
          children.add(SizedBox(width: smallPadding));
        }
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }
    
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mediumPadding, vertical: smallPadding),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 32, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: smallPadding),
                    Expanded(
                      child: Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Level ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50)),
                                Text('$level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)),
                                SizedBox(width: largePadding),
                                Icon(Icons.diamond, color: Colors.blueAccent, size: 60),
                                SizedBox(width: smallPadding),
                                Text('$diamonds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.card_giftcard, color: Colors.amber, size: 60),
                  ],
                ),
              ),

              // Centered main content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Image
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: EdgeInsets.only(top: screenHeight * 0.01, bottom: 0),
                          width: imageContainerSize,
                          height: imageContainerSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black26),
                          ),
                          child: Image.asset(
                            'assets/questions/${question.imageName}',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Text('Không thể tải ảnh'));
                            },
                          ),
                        ),
                      ),
                    ),
                    // Banner ads (no gap)
                    Container(
                      width: imageContainerSize,
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Text(
                        'Banner ads',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    // Answer grid
                    Padding(
                      padding: EdgeInsets.only(top: mediumPadding, bottom: smallPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (row1Count > 0) buildAnswerRow(0, row1Count),
                          if (row2Count > 0) ...[
                            SizedBox(height: smallPadding),
                            buildAnswerRow(maxPerRow, row2Count),
                          ],
                        ],
                      ),
                    ),
                    // Character grid (always 2 rows, always maxRowLength per row)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int maxRowLength = 8;
                        double dynamicCharButtonSize = (constraints.maxWidth - smallPadding * (maxRowLength - 1) - mediumPadding * 2) / maxRowLength;
                        List<Widget> buildCharRow(int start, int end) {
                          List<Widget> rowChildren = [];
                          for (int i = start; i < end; i++) {
                            if (i > start) rowChildren.add(SizedBox(width: smallPadding));
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
                                          style: TextStyle(fontSize: fontSizeChar, fontWeight: FontWeight.bold),
                                        ),
                                      )
                              );
                            } else {
                              rowChildren.add(SizedBox(width: dynamicCharButtonSize, height: dynamicCharButtonSize));
                            }
                          }
                          // Always fill to maxRowLength
                          while (rowChildren.length < maxRowLength) {
                            if (rowChildren.length > 0) rowChildren.add(SizedBox(width: smallPadding));
                            rowChildren.add(SizedBox(width: dynamicCharButtonSize, height: dynamicCharButtonSize));
                          }
                          return rowChildren;
                        }
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: mediumPadding),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: buildCharRow(0, maxRowLength),
                              ),
                              SizedBox(height: smallPadding),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: buildCharRow(maxRowLength, maxRowLength * 2),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Function buttons at the bottom
              Padding(
                padding: EdgeInsets.symmetric(horizontal: largePadding, vertical: mediumPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
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
                      onPressed: () {},
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
                      onPressed: () {},
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
              SizedBox(height: mediumPadding),
            ],
          ),
        ),
      ),
    );
  }
}