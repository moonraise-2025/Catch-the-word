import 'package:flutter/material.dart';
import 'StartScreen.dart';

void main()  {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đuổi hình bắt chữ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}