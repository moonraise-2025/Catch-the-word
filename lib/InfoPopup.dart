import 'package:flutter/material.dart';

class InfoPopup extends StatelessWidget {
  const InfoPopup({super.key});

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
            margin: EdgeInsets.only(top: screenHeight * 0.1), // Margin động để chừa chỗ cho tiêu đề/logo
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
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SizedBox(height: screenHeight * 0.01), // Để tránh logo đè lên
                    Text(
                      'Thông Tin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF626DD2)),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      'Đuổi hình bắt chữ là trò chơi trí tuệ, nơi bạn đoán câu, từ qua các hình ảnh gợi ý.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth * 0.036,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      'Mẹo chơi tốt',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF626DD2)),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      '1. Nghĩ nhiều nghĩa/âm, từ Hán-Việt cho hình ảnh.\n(VD: ngựa = mã, tim = tâm...)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth * 0.036,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      '2. Chơi cùng bạn bè để có nhiều ý tưởng hơn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth * 0.036,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      '3. Dùng gợi ý trong app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: screenWidth * 0.036,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Logo
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 0.7,
              ),
            ),
          ),

          // Nút đóng
          Positioned(
            top: screenHeight * 0.09,
            right: screenWidth * 0.025,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/images/icon_close.png',
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.65),
        ],
      ),
    );
  }
}
