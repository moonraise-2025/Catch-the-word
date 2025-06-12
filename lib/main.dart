import 'package:flutter/material.dart';
import 'package:duoihinhbatchu/StartScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Bắt Chữ'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
                repeat: ImageRepeat.noRepeat,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Player Name Input
                  // Container(
                  //   margin: const EdgeInsets.symmetric(horizontal: 50),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withOpacity(0.7),
                  //     borderRadius: BorderRadius.circular(10),
                  //     border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  //   ),
                  //   child: TextField(
                  //     controller: _nameController,
                  //     decoration: const InputDecoration(
                  //       hintText: 'Nhập tên của bạn',
                  //       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  //       border: InputBorder.none,
                  //     ),
                  //     style: const TextStyle(
                  //       fontSize: 16,
                  //       color: Colors.black87,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 20),
                  // Start Game Button
                  ElevatedButton(
                    onPressed: () {
                      print('Đã bấm nút BẮT CHỮ');
                      print('Tên người chơi: ${_nameController.text}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StartScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'BẮT CHỮ',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              'Version: 9.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      
    );
  }
}
