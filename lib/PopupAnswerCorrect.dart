import 'package:flutter/material.dart';

import 'AnimatedButton.dart';

class PopupAnswerCorrect extends StatefulWidget {
  final VoidCallback onNext;

  const PopupAnswerCorrect({Key? key, required this.onNext}) : super(key: key);

  @override
  State<PopupAnswerCorrect> createState() => _PopupAnswerCorrectState();
}

class _PopupAnswerCorrectState extends State<PopupAnswerCorrect> {
  bool _isNextButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Stack(
        children: [
          Container(
            width: screenWidth * 0.90,
            height: screenHeight * 0.50,
            margin: EdgeInsets.only(top: screenHeight * 0.1),
            // Margin động để chừa chỗ cho tiêu đề/logo
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.025,
            ),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/bg_popup.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(children: [
              // Ảnh hiệu ứng phủ toàn bộ (căn giữa, phủ toàn khung popup)
              Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 1,
                  child: Image.asset(
                    'assets/images/laplanh.png',
                    width: screenWidth * 10,
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
                  width: screenWidth * 10,
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
                      SizedBox(height: screenHeight * 0.05),
                      Text(
                        'CHÍNH XÁC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.1,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF626DD2),
                            decoration: TextDecoration.none,
                            fontFamily: 'Roboto'
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '5',
                            style: TextStyle(
                                fontSize: screenWidth * 0.15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C86F2),
                                decoration: TextDecoration.none,
                                fontFamily: 'Roboto'
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Image.asset(
                            'assets/images/diamond.png',
                            width: screenWidth * 0.15,
                            height: screenHeight * 0.15,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      AnimatedScale(
                        scale: _isNextButtonPressed ? 0.95 : 1.0, // Co lại 5% khi nhấn, về 100% khi nhả
                        duration: const Duration(milliseconds: 100),
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _isNextButtonPressed = true),
                          onTapUp: (_) {
                            setState(() {
                              _isNextButtonPressed = false; // Đặt lại trạng thái không nhấn
                            });

                          },
                          onTapCancel: () => setState(() => _isNextButtonPressed = false),

                          child: AnimatedButton(
                            text: 'TIẾP TỤC',
                            onPressed: () {widget.onNext();},
                            width: screenWidth * 0.65,
                            height: screenHeight * 0.06,
                            fontSize: screenWidth * 0.06,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ]),
          ),
          Positioned(
            top: screenHeight * 0.02, // Điều chỉnh giá trị này cẩn thận
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo.png',
                width: screenWidth *
                    0.7, // Chiều rộng logo theo chiều rộng màn hình
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.65),
        ],
      ),
    );
  }
}