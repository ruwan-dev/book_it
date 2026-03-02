import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_loader.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // තත්පර 3ක් ලෝඩර් එක පෙන්වා ඉන්පසු AuthWrapper එකට යොමු කරයි.
    // මෙහිදී pushReplacement පාවිච්චි කරන්නේ යූසර්ට ආපහු Splash Screen එකට එන්න බැරි වෙන්නයි.
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // ඇප් එකේ තේමාවට ගැලපෙන පසුබිම් වර්ණය
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // අපි කලින් හදපු අයිකන් මාරු වෙන ලෝඩර් එක
            // සයිස් එක 60.0 ලෙස ලබා දී ඇත
            CustomLoader(size: 60.0), 
          ],
        ),
      ),
    );
  }
}