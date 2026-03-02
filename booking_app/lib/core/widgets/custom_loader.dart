import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomLoader extends StatefulWidget {
  final double size;
  const CustomLoader({super.key, this.size = 60.0}); // Default 60 Splash එකට ගැලපෙන්න

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<IconData> _icons = [
    Icons.content_cut,
    Icons.spa,
    Icons.fitness_center,
    Icons.calendar_month,
  ];

  @override
  void initState() {
    super.initState();
    // HTML එකේ වගේම 0.8s (මිලි තත්පර 800) කට වරක් මාරු වෙනවා
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _icons.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // වේගවත් මාරුවීමක් (Transition)
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Icon(
        _icons[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        size: widget.size,
        color: AppColors.primary, // #6C63FF
      ),
    );
  }
}