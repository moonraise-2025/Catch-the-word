import 'package:flutter/material.dart';

import 'AnimatedButton.dart';

class PopupAnswerCorrect extends StatefulWidget {
  final VoidCallback onNext;

  const PopupAnswerCorrect({Key? key, required this.onNext}) : super(key: key);

  @override
  State<PopupAnswerCorrect> createState() => _PopupAnswerCorrectState();
}

class _PopupAnswerCorrectState extends State<PopupAnswerCorrect> {

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 800,
            width: screenWidth * 0.80,
            margin: const EdgeInsets.only(top: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/bg_popup.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
                children: [
                  // Ảnh hiệu ứng phủ toàn bộ (căn giữa, phủ toàn khung popup)
                  Align(
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: 1,
                      child: Image.asset(
                        'assets/images/laplanh.png',
                         width: 1300,
                        // height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Ảnh ngôi sao sáng (cũng căn giữa luôn)
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/sanglen.png',
                      width: 1000,
                      // height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),

                  Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'CHÍNH XÁC',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8E61DC),
                        ),
                      ),
                      const SizedBox(height: 100),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            '5',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C86F2),
                            ),
                          ),
                          SizedBox(width: 15),
                          Icon(Icons.diamond,
                              color: Colors.blueAccent, size: 60),
                        ],
                      ),
                      const SizedBox(height: 100),
                          AnimatedButton(
                            text: 'TIẾP TỤC',
                            onPressed: widget.onNext,
                          )
                    ],
                  ),
                ),
              ),
            ]),
          ),
          Positioned(
            top: -600,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo.png',
                width: 500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
