import 'package:flutter/material.dart';

class PopupWatchVideo extends StatelessWidget {
  const PopupWatchVideo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: screenWidth * 0.70,
            margin: const EdgeInsets.only(top: 80), // để chừa chỗ cho tiêu đề
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30), // padding cân trái/phải
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Bạn muốn qua màn chơi?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Thêm logic phát quảng cáo ở đây
                      Navigator.of(context).pop(); // Tạm thời đóng popup
                    },
                    icon: const Icon(Icons.ondemand_video, color: Colors.white),
                    label: const Text("Xem Quảng Cáo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border.all(color: Colors.pink, width: 2),
              ),
              child: const Text(
                "Qua Màn Bằng Quảng Cáo",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
