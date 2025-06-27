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
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    return Scaffold(
      body: Builder(
        builder: (context) {
          return Container(
            width: screenWidth,
            height: screenHeight,
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
                        padding: EdgeInsets.only(bottom: screenHeight * 0.08),
                        child: Image.asset(
                          'assets/images/logodhbc.png',
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.25,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      if (lastLevel == null || lastLevel == 1) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.025,
                            ),
                            textStyle: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                            ),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.025,
                            ),
                            textStyle: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          onPressed: _continueGame,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Tiếp tục'),
                              SizedBox(height: screenHeight * 0.01),
                              Text('Level $lastLevel', style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.lightBlue)),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.08),
                    ],
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.04,
                  right: screenWidth * 0.04,
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
                          padding: EdgeInsets.all(screenWidth * 0.025),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.lightBlue[200],
                          ),
                          child: Icon(Icons.info, size: screenWidth * 0.07, color: Colors.black),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
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
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: Icon(Icons.settings, size: screenWidth * 0.08, color: Colors.black),
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