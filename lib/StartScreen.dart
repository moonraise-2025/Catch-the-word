import 'package:flutter/material.dart';
import 'GameScreen.dart';
import 'SettingPopup.dart';
import 'InfoPopup.dart';

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
                image: AssetImage('assets/images/background2.png'),
                fit: BoxFit.cover,
                repeat: ImageRepeat.noRepeat,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BẮT CHỮ',
                        style: TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              offset: Offset(3, 3),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                          textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Colors.black),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GameScreen(),
                            ),
                          );
                        },
                        child: const Text('Bắt đầu'),
                      ),
                      SizedBox(height: 20),
                      Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                              textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: Colors.black),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GameScreen(),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // để chiều cao vừa khít nội dung
                              children: const [
                                Text(
                                  'Tiếp tục',
                                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Level N', // bạn có thể thay bằng level thực tế sau
                                  style: TextStyle(fontSize: 20, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 32,
                  bottom: 32,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const SettingPopup();
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Icon(Icons.settings, size: 48, color: Colors.black),
                    ),
                  ),
                ),
                Positioned(
                  right: 32,
                  bottom: 32,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const InfoPopup();
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.lightBlue[200],
                      ),
                      child: const Icon(Icons.info, size: 40, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 