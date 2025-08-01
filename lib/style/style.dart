import 'package:flutter/material.dart';

class AppColors {
  static const primary = Colors.deepPurple;
  static const secondary = Color(0xFF42A5F5);
  static const danger = Color(0xFFD32F2F);
}

class AppButtonStyle {
  static ButtonStyle newPage = ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
  );

  static ButtonStyle backPage = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey,
    foregroundColor: Colors.white,
  );
}
