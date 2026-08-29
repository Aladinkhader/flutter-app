import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PlaceholderTab extends StatelessWidget {
  final String label;
  const PlaceholderTab({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
