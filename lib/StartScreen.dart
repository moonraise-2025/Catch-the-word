import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          return Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
                repeat: ImageRepeat.noRepeat,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    child: const Text(
                      'Điểm: 0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Đuổi hình bắt chữ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 60,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Text(
                          'Chơi ngay',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 32,
                  bottom: 32,
                  child: Icon(Icons.volume_up, size: 48),
                ),
                Positioned(
                  right: 32,
                  bottom: 32,
                  child: Icon(Icons.diamond, size: 48, color: Colors.blueAccent),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 