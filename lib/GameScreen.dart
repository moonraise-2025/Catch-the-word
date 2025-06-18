import 'package:flutter/material.dart';
import 'dart:math';

class Question {
  final String imageName;
  final String answer;
  Question({required this.imageName, required this.answer});
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final List<Question> questions = [
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
  int currentQuestion = 0;
  int level = 1;
  int diamonds = 0;

  late List<String> answerSlots;
  late List<String> charOptions;
  late List<bool> charUsed;
  int currentSlot = 0;
  bool isCorrect = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initGame();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

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
  }

  List<String> _generateCharOptions(String answer) {
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    List<String> chars = answer.split('');
    Random rnd = Random();
    
    // Tính số lượng chữ gây nhiễu dựa vào độ dài đáp án
    int numDistractors;
    if (answer.length <= 5) {
      // Đáp án ngắn (≤ 5 chữ): 2-3 chữ gây nhiễu
      numDistractors = 2 + rnd.nextInt(2); // Random 2 hoặc 3
    } else if (answer.length <= 10) {
      // Đáp án trung bình (6-10 chữ): 4-5 chữ gây nhiễu
      numDistractors = 4 + rnd.nextInt(2); // Random 4 hoặc 5
    } else {
      // Đáp án dài (> 10 chữ)
      if (answer.length < 16) {
        // Nếu chưa đủ 16 chữ, thêm cho đủ 16 chữ
        numDistractors = 16 - answer.length;
      } else {
        // Nếu đã dài hơn 16 chữ, thêm 1-2 chữ gây nhiễu
        numDistractors = 1 + rnd.nextInt(2); // Random 1 hoặc 2
      }
    }

    // Thêm các chữ gây nhiễu
    while (chars.length < answer.length + numDistractors) {
      String c = alphabet[rnd.nextInt(alphabet.length)];
      if (!answer.contains(c)) {
        chars.add(c);
      }
    }
    chars.shuffle();
    return chars;
  }

  void _onCharTap(int idx) {
    if (currentSlot < answerSlots.length && !charUsed[idx]) {
      setState(() {
        answerSlots[currentSlot] = charOptions[idx];
        charUsed[idx] = true;
        currentSlot++;
        if (currentSlot == answerSlots.length) {
          String userAnswer = answerSlots.join('');
          isCorrect = userAnswer == questions[currentQuestion].answer.toUpperCase();
          if (isCorrect) {
            Future.delayed(const Duration(milliseconds: 300), showCorrectDialog);
          }
        }
      });
    }
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

  void _onBackspace() {
    if (currentSlot > 0) {
      setState(() {
        currentSlot--;
        String char = answerSlots[currentSlot];
        int idx = charOptions.indexOf(char);
        if (idx != -1) charUsed[idx] = false;
        answerSlots[currentSlot] = '';
        isCorrect = false;
      });
    }
  }

  void showCorrectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 380,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blueAccent, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 60),
                      SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 60),
                      SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 60),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Tuyệt vời',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        fontFamily: 'Pacifico',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.pink[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.card_giftcard, color: Colors.pink, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.diamond, color: Colors.blueAccent, size: 48),
                      SizedBox(width: 12),
                      Text(
                        '+5',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontFamily: 'Pacifico',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.ondemand_video, color: Colors.white),
                        label: const Text('x5'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Pacifico'),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            if (currentQuestion < questions.length - 1) {
                              currentQuestion++;
                              level++;
                              diamonds += 5;
                              _initGame();
                            } else {
                              // Hết câu hỏi, có thể hiện thông báo hoặc reset
                              currentQuestion = 0;
                              level = 1;
                              diamonds = 0;
                              _initGame();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, fontFamily: 'Pacifico'),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tiếp Nè'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double imageContainerSize = screenWidth * 0.4; // Giảm kích thước khung ảnh
    final double answerBoxSize = screenWidth * 0.09;   // Giảm kích thước ô đáp án
    final double charButtonSize = screenWidth * 0.1;  // Giảm kích thước nút chữ cái
    final double smallPadding = screenWidth * 0.01;
    final double mediumPadding = screenWidth * 0.02;
    final double largePadding = screenWidth * 0.08;
    final double fontSizeAnswer = screenWidth * 0.055; // Giảm kích thước font đáp án
    final double fontSizeChar = screenWidth * 0.055; // Giảm kích thước font chữ cái

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background2.png'),
            fit: BoxFit.cover,
            repeat: ImageRepeat.noRepeat,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mediumPadding, vertical: smallPadding),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 32, color: Colors.white),
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
                                const Text('Level ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50, fontFamily: 'Pacifico')),
                                Text('$level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50, fontFamily: 'Pacifico')),
                                SizedBox(width: largePadding),
                                Icon(Icons.diamond, color: Colors.blueAccent, size: 60),
                                SizedBox(width: smallPadding),
                                Text('$diamonds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50, fontFamily: 'Pacifico')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 60),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(screenWidth * 0.12, screenHeight * 0.3, screenWidth * 0.12, screenWidth * 0.05), // Tăng padding phía trên từ 0.2 lên 0.3
                        child: Container(
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
                              print('Error loading image: $error');
                              return const Center(
                                child: Text(
                                  'Không thể tải ảnh',
                                  style: TextStyle(color: Colors.red),
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
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.only(top: screenHeight * 0.03), // Tăng margin phía trên từ 0.02 lên 0.03
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int i = 0; i < (answerSlots.length + 1) ~/ 2; i++)
                                      GestureDetector(
                                        onTap: () => _onAnswerSlotTap(i),
                                        child: Container(
                                          width: answerBoxSize,
                                          height: answerBoxSize,
                                          margin: EdgeInsets.symmetric(horizontal: smallPadding / 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.black, width: 2),
                                            color: Colors.white,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            answerSlots[i],
                                            style: TextStyle(
                                              fontSize: fontSizeAnswer,
                                              fontWeight: FontWeight.bold,
                                              color: currentSlot == answerSlots.length
                                                  ? (isCorrect ? Colors.green : Colors.red)
                                                  : Colors.black,
                                              fontFamily: 'Pacifico',
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: smallPadding),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int i = (answerSlots.length + 1) ~/ 2; i < answerSlots.length; i++)
                                      GestureDetector(
                                        onTap: () => _onAnswerSlotTap(i),
                                        child: Container(
                                          width: answerBoxSize,
                                          height: answerBoxSize,
                                          margin: EdgeInsets.symmetric(horizontal: smallPadding / 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.black, width: 2),
                                            color: Colors.white,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            answerSlots[i],
                                            style: TextStyle(
                                              fontSize: fontSizeAnswer,
                                              fontWeight: FontWeight.bold,
                                              color: currentSlot == answerSlots.length
                                                  ? (isCorrect ? Colors.green : Colors.red)
                                                  : Colors.black,
                                              fontFamily: 'Pacifico',
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(width: mediumPadding),
                            
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Sử dụng Spacer để đẩy phần dưới cùng xuống cuối màn hình
              const Spacer(),

              // Phần các nút chữ cái nằm ở dưới cùng
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: smallPadding / 2,
                    runSpacing: smallPadding,
                    children: [
                      for (int i = 0; i < charOptions.length; i++)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: smallPadding / 2),
                          child: charUsed[i]
                              ? SizedBox(
                                  width: charButtonSize,
                                  height: charButtonSize,
                                )
                              : ElevatedButton(
                                  onPressed: () => _onCharTap(i),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(charButtonSize, charButtonSize),
                                    backgroundColor: Colors.purpleAccent,
                                  ),
                                  child: Text(
                                    charOptions[i],
                                    style: TextStyle(fontSize: fontSizeChar, fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: mediumPadding), // Thêm khoảng cách ở cuối cùng để không bị sát mép
            ],
          ),
        ),
      ),
    );
  }
}