import 'package:flutter/material.dart';
import 'package:hanziilearnapp/core/constants.dart';
import 'package:hanziilearnapp/screens/bottom_nav.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  void _navigateToMain() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const BottomNav()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/logo/background.jpg', fit: BoxFit.contain),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                Text(
                  '汉字',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: AppColors.label,
                    shadows: [
                      Shadow(
                        color: AppColors.label.withOpacity(0.3),
                        offset: const Offset(2, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hanzi Learn',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelOnboarding,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 400),
                Text(
                  'Học tiếng Trung mỗi ngày',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.labelOnboarding.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
