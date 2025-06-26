import 'package:flutter/material.dart';
import 'GameScreen.dart';
import 'SettingPopup.dart';
import 'InfoPopup.dart';
import 'audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int? lastLevel;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLastLevel();
  }

  Future<void> _loadLastLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastLevel = prefs.getInt('lastLevel');
      loading = false;
    });
  }

  void _startNewGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastLevel', 1);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
    _loadLastLevel();

  }

  void _continueGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          initialLevel: lastLevel ?? 1,
        ),
      ),
    );
    _loadLastLevel();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          return Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BackgroundDHBC.png'),
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
                      Padding( 
                        padding: const EdgeInsets.only(bottom: 350),
                        child: Image.asset(
                          'assets/images/logodhbc.png',
                          width: 800, 
                          height: 400,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 60),
                      if (lastLevel == null || lastLevel == 1) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            textStyle: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          onPressed: _startNewGame,
                          child: const Text('Chơi ngay'),
                        ),
                      ] else ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.lightBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            textStyle: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          onPressed: _continueGame,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Tiếp tục', ),
                              const SizedBox(height: 8),
                              Text('Level $lastLevel', style: const TextStyle(fontSize: 30, color: Colors.lightBlue)),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 100),
                    ],
                  ),
                ),
                Positioned(
                  top: 32,
                  right: 32,
                  child: Row(
                    children: [
                      GestureDetector(
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

                      const SizedBox(width: 16), // khoảng cách giữa hai icon
                      GestureDetector(
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
                          child: const Icon(Icons.settings, size: 50, color: Colors.black),
                        ),
                      ),
                    ],
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