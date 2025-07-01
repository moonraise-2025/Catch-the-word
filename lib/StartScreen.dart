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
    final double buttonWidth = screenWidth * 0.7;
    final double buttonHeight = screenHeight * 0.06;
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
                      SizedBox(height: screenHeight * 0.15),
                      if (lastLevel == null || lastLevel == 1) ...[
                        SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              textStyle: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _startNewGame,
                            child: const Text('Chơi ngay', textAlign: TextAlign.center),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF616FD3),
                              textStyle: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _continueGame,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('TIẾP TỤC', textAlign: TextAlign.center),
                                Text('(Level $lastLevel)',
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Color(0xFF4E4E51))),
                              ],
                            ),
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
                        child: Image.asset(
                          'assets/images/thongtin.png',
                          width: screenWidth * 0.07,
                          height: screenWidth * 0.07,
                          fit: BoxFit.contain,
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
                        child: Image.asset(
                          'assets/images/setting.png',
                          width: screenWidth * 0.07,
                          height: screenWidth * 0.07,
                          fit: BoxFit.contain,
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