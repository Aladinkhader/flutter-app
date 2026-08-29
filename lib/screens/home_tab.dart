import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _WelcomeCard(),
        const SizedBox(height: 24),
        Text(
          'مختارات من المحاضرات',
          style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.lightText,
          ),
        ),
        const SizedBox(height: 12),
        const _LectureCardPlaceholder(),
        const SizedBox(height: 10),
        const _LectureCardPlaceholder(),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'استمع إلى أحدث المواعظ والبرامج والخطب العلمية',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: AppColors.lightText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'تصفح كل الأقسام',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LectureCardPlaceholder extends StatelessWidget {
  const _LectureCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardGradientStart.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline, color: AppColors.primaryTeal, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسم المحاضرة (بيانات حقيقية بالمرحلة 2)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainText,
                  ),
                ),
                Text(
                  'اسم القسم',
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: AppColors.secondaryText.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.bookmark_border, color: AppColors.secondaryText.withOpacity(0.7), size: 20),
        ],
      ),
    );
  }
}
