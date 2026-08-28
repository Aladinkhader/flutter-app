import 'package:flutter/material.dart';

/// الألوان الأساسية لتطبيق الشيخ د. محمد الأمين إسماعيل
/// مستخرجة من تصميم HTML المرجعي - لا تغيّر هذه القيم
class AppColors {
  AppColors._();

  /// الخلفية الأساسية
  static const Color background = Color(0xFF0F3D3B);

  /// خلفية داكنة جدًا (تُستخدم في Splash و Bottom Nav)
  static const Color veryDarkBackground = Color(0xFF092726);

  /// خلفية البطاقات الداكنة
  static const Color cardDark = Color(0xFF124845);

  /// لون بداية تدرج البطاقات (Card Gradient)
  static const Color cardGradientStart = Color(0xFF237571);

  /// لون نهاية تدرج البطاقات
  static const Color cardGradientEnd = Color(0xFF18524F);

  /// اللون الأساسي Teal (أزرار، أيقونات نشطة، حدود)
  static const Color primaryTeal = Color(0xFF3BB1AA);

  /// نص ثانوي
  static const Color secondaryText = Color(0xFF89D6D1);

  /// نص فاتح
  static const Color lightText = Color(0xFFB4ECE8);

  /// النص الرئيسي (أبيض)
  static const Color mainText = Color(0xFFFFFFFF);

  /// تدرج البطاقات الرئيسية (Hero Card)
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardGradientStart, cardGradientEnd],
  );

  /// تدرج بطاقات الأقسام (أغمق قليلاً)
  static const LinearGradient categoryCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18524F), Color(0xFF103B39)],
  );
}
