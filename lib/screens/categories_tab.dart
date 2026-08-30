import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/archive_service.dart';
import 'section_lectures_screen.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = ArchiveService.sections;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
        children: sections.entries.map((entry) {
          return _CategoryCard(
            identifier: entry.key,
            title: entry.value,
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String identifier;
  final String title;

  const _CategoryCard({required this.identifier, required this.title});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SectionLecturesScreen(
              identifier: widget.identifier,
              sectionTitle: widget.title,
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _pressed ? -4 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.categoryCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? AppColors.primaryTeal.withOpacity(0.6)
                  : AppColors.primaryTeal.withOpacity(0.2),
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.3),
                      blurRadius: 18,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'عرض المحاضرات',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
