import 'package:flutter/material.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  final String imageName; // ví dụ: 'cau1.png'
  final String answer;    // ví dụ: 'APPLE'

  const GameScreen({super.key, required this.imageName, required this.answer});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<String> answerSlots;
  late List<String> charOptions;
  late List<bool> charUsed;
  int currentSlot = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    // Tạo các ô đáp án rỗng
    answerSlots = List.filled(widget.answer.length, '');
    // Sinh danh sách chữ cái (đáp án + nhiễu)
    charOptions = _generateCharOptions(widget.answer.toUpperCase());
    charUsed = List.filled(charOptions.length, false);
    currentSlot = 0;
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
      });
    }
  }

  void _onBackspace() {
    if (currentSlot > 0) {
      setState(() {
        currentSlot--;
        // Tìm lại index của chữ cái vừa nhập để mở lại nút
        String char = answerSlots[currentSlot];
        int idx = charOptions.indexOf(char);
        if (idx != -1) charUsed[idx] = false;
        answerSlots[currentSlot] = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Thanh trên cùng
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
                          Text('Điểm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
            // Ảnh câu đố
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 300,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black26),
                ),
                child: Image.asset(
                  'assets/questions/${widget.imageName}',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Các ô đáp án
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.backspace),
                  onPressed: _onBackspace,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Hai hàng chữ cái
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
