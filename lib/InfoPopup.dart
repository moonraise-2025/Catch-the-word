import 'package:flutter/material.dart';

class InfoPopup extends StatelessWidget {
  const InfoPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            height: 800,
            width: screenWidth * 0.80,
            margin: const EdgeInsets.only(top: 200), // để chừa chỗ cho tiêu đề
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30), // padding cân trái/phải
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Thông Tin',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFF8E61DC)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Đuổi hình bắt chữ là trò chơi trí tuệ, nơi bạn đoán câu, từ qua các hình ảnh gợi ý.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Mẹo chơi tốt',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFF8E61DC)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '1. Nghĩ nhiều nghĩa/âm, từ Hán-Việt cho hình ảnh.\n(VD: ngựa = mã, tim = tâm...)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '2. Chơi cùng bạn bè để có nhiều ý tưởng hơn',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '3. Dùng gợi ý trong app',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
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
          // Nút đóng ở góc phải trên
          Positioned(
            top: 100,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/images/icon_close.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
