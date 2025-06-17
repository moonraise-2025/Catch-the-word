import 'package:flutter/material.dart';
import 'GameScreen.dart';

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
                      'Level: 0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        fontFamily: 'Pacifico',
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BẮT CHỮ',
                        style: TextStyle(
                          fontSize: 90,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 8,
                          fontFamily: 'Pacifico',
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
                          textStyle: const TextStyle(fontSize: 30, fontFamily: 'Pacifico'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Colors.black12),
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
                        child: const Text('Chơi ngay'),
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