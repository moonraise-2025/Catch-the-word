import 'package:flutter/material.dart';

class InfoPopup extends StatelessWidget {
  const InfoPopup({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy chiều rộng và chiều cao của màn hình hiện tại
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
            Container(
              // Điều chỉnh chiều cao và chiều rộng dựa trên kích thước màn hình
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
              child: Center(
                child: SingleChildScrollView( // SingleChildScrollView giúp nội dung cuộn được nếu quá dài
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.03),
                      // Khoảng trống động
                      Text(
                        'Thông Tin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.08,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8E61DC)),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Đuổi hình bắt chữ là trò chơi trí tuệ, nơi bạn đoán câu, từ qua các hình ảnh gợi ý.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Mẹo chơi tốt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8E61DC)),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        '1. Nghĩ nhiều nghĩa/âm, từ Hán-Việt cho hình ảnh.\n(VD: ngựa = mã, tim = tâm...)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        '2. Chơi cùng bạn bè để có nhiều ý tưởng hơn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.034,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        '3. Dùng gợi ý trong app',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
            ),
            // Định vị logo tương đối với kích thước màn hình
            Positioned(
              top: screenHeight * 0.02, // Điều chỉnh giá trị này cẩn thận
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: screenWidth * 0.7, // Chiều rộng logo theo chiều rộng màn hình
                ),
              ),
            ),
            // Nút đóng ở góc phải trên
            Positioned(
              top: screenHeight * 0.05, // Vị trí theo chiều cao màn hình
              right: screenWidth * 0.02, // Vị trí theo chiều rộng màn hình
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Image.asset(
                  'assets/images/icon_close.png',
                  width: screenWidth * 0.06,// Kích thước theo chiều rộng màn hình
                  height:screenWidth * 0.06, // Kích thước theo chiều rộng màn hình
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
