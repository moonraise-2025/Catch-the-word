import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  final double? width;
  final double? height;
  final double? fontSize;

  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.width,
    this.height,
    this.fontSize,
  }) : super(key: key);


  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward(from: 0.0);
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 150), () {
      widget.onPressed();
      setState(() => _isPressed = false);
    });
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double buttonWidth = widget.width ?? screenWidth * 0.5;
    final double buttonHeight = widget.height ?? screenHeight * 0.07;
    final double textFontSize = widget.fontSize ?? screenWidth * 0.06;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: buttonWidth,
            height:buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screenWidth * 0.02), // Bo góc động
              gradient: RadialGradient(
                center: Alignment.center,
                radius: _animation.value * 2,
                colors: _isPressed
                    ? [const Color(0xFF8E61DC), const Color(0xFF8E61DC).withOpacity(0.5)]
                    : [Colors.white, Colors.white],
              ),
            ),
            child: Center(
              child: Text(
                widget.text,

                style: TextStyle(
                  fontSize:textFontSize,
                  fontWeight: FontWeight.bold,
                  color: _isPressed ? Colors.white : const Color(0xFF8E61DC),
                  decoration: TextDecoration.none,
                    fontFamily: 'Roboto'
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}