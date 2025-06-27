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
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
        backgroundColor: Colors.transparent,
        // Sử dụng ConstrainedBox để đặt kích thước tối đa cho nội dung popup.
        // Điều này giúp popup không quá lớn trên màn hình rộng (ví dụ: máy tính bảng).
        child: ConstrainedBox(
        constraints: BoxConstraints(
        maxWidth: screenWidth * 0.9, // Chiều rộng tối đa 90% màn hình
        maxHeight: screenHeight * 0.6, // Chiều cao tối đa 90% màn hình
    ),
          child: Stack(
            children: [
              Container(// Điều chỉnh chiều cao và chiều rộng dựa trên kích thước màn hình
                height: screenHeight * 0.7,// Chiếm 70% chiều cao màn hình
                width: screenWidth * 0.85,// Chiếm 85% chiều rộng màn hình
                margin: EdgeInsets.only(top: screenHeight * 0.1),// Margin động để chừa chỗ cho tiêu đề/logo
                padding: EdgeInsets.symmetric( // Padding cân đối dựa trên kích thước màn hình
                horizontal: screenWidth * 0.05, // 5% chiều rộng màn hình cho padding ngang
                vertical: screenHeight * 0.03, // 3% chiều cao màn hình cho padding dọc
          ),
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
                         width:  screenWidth * 10,
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
                        style:  TextStyle(
                          fontSize: screenWidth * 0.08 ,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8E61DC),
                        ),
                      ),
                       SizedBox(height: screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:  [
                          Text(
                            '5',
                            style: TextStyle(
                              fontSize: screenWidth * 0.1 ,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C86F2),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Image.asset(
                            'assets/images/diamond.png',
                            width: screenWidth * 0.1 ,
                            height: screenHeight * 0.1,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.04),

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
        ],
      ),
        )
    );
  }
}
