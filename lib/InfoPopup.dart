import 'package:flutter/material.dart';

class InfoPopup extends StatelessWidget {
  const InfoPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 80), // để chừa chỗ cho tiêu đề
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30), // padding cân trái/phải
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: SingleChildScrollView( // nếu nội dung quá dài
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, // căn giữa theo chiều ngang

                children: [
                  const SizedBox(height: 40), // khoảng cách với tiêu đề
                  Text(
                    'Đuổi hình bắt chữ là trò chơi trí tuệ, nơi bạn đoán câu, từ qua các hình ảnh gợi ý.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Text(
                    'Mẹo chơi tốt',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '1. Nghĩ nhiều nghĩa/âm, từ Hán-Việt cho hình ảnh. (VD: ngựa = mã, tim = tâm...)',
                    textAlign: TextAlign.center,

                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '2. Chơi cùng bạn bè để có nhiều ý tưởng hơn',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '3. Dùng gợi ý trong app',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Phần tiêu đề nằm sát trên cùng
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border.all(color: Colors.pink, width: 2),
              ),
              child: const Text(
                'Thông tin',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Nút đóng ở góc phải trên
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, size: 30, color: Colors.blueAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}