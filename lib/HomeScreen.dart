import 'package:flutter/material.dart';
import 'StartScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
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
                const SizedBox(height: 40),
                ElevatedButton(
                    onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StartScreen()),
                    );
                    },
                    child: const Text('Start Game'),
                ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}