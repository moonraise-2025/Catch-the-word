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

class _GameScreenState extends State<GameScreen> {
  final List<Question> questions = [
    Question(imageName: 'cau1.png', answer: 'CƯỚPBIỂN'),
    Question(imageName: 'cau2.png', answer: 'THUỶTINH'),
    
  ];
  int currentQuestion = 0;

  late List<String> answerSlots;
  late List<String> charOptions;
  late List<bool> charUsed;
  int currentSlot = 0;
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final answer = questions[currentQuestion].answer.toUpperCase();
    answerSlots = List.filled(answer.length, '');
    charOptions = _generateCharOptions(answer);
    charUsed = List.filled(charOptions.length, false);
    currentSlot = 0;
    isCorrect = false;
  }

  List<String> _generateCharOptions(String answer) {
    const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    List<String> chars = answer.split('');
    Random rnd = Random();
    while (chars.length < 10) {
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
              width: 320,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                      Icon(Icons.star, color: Colors.amber, size: 40),
                      SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 40),
                      SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 40),
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
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.orange[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.pink[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.card_giftcard, color: Colors.pink, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.diamond, color: Colors.blueAccent, size: 36),
                      SizedBox(width: 8),
                      Text(
                        '+5',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: null, // Tạm thời chưa hoạt động
                        icon: const Icon(Icons.ondemand_video, color: Colors.white),
                        label: const Text('x5'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                              _initGame();
                            } else {
                              // Hết câu hỏi, có thể hiện thông báo hoặc reset
                              currentQuestion = 0;
                              _initGame();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          SizedBox(width: 24),
                          Text('Số kim cương', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.lightbulb, color: Colors.amber, size: 36),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black26),
                ),
                child: Image.asset(
                  'assets/questions/${question.imageName}',
                  fit: BoxFit.contain,
                ),
              ),
            ),
  
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < answerSlots.length; i++)
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      answerSlots[i],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: currentSlot == answerSlots.length
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Colors.black,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.backspace),
                  onPressed: _onBackspace,
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (int row = 0; row < 2; row++)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int col = 0; col < 5; col++)
                    if (row * 5 + col < charOptions.length)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          onPressed: charUsed[row * 5 + col]
                              ? null
                              : () => _onCharTap(row * 5 + col),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: Text(
                            charOptions[row * 5 + col],
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
