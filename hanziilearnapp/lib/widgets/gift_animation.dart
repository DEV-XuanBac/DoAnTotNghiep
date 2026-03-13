import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GiftAnimation extends StatefulWidget {
  const GiftAnimation({super.key});

  @override
  State<GiftAnimation> createState() => _GiftAnimationState();
}

class _GiftAnimationState extends State<GiftAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: GestureDetector(
        onTap: () {},
        child: Image.asset(
          'assets/iconic/giftbox.png',
          width: 36.w,
          height: 36.h,
        ),
      ),
      builder: (context, child) {
        double rotate = sin(_controller.value * pi * 4) * 0.1;
        double jump = sin(_controller.value * pi * 2) * -0.4;
        double glow = (sin(_controller.value * pi * 2) + 1) * 5; // Shake effect
        return Transform.translate(
          offset: Offset(0, jump),
          child: Transform.rotate(
            angle: rotate,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: glow,
                    spreadRadius: glow / 2,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
