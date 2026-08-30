import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

void showSheikhBioDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'من هو الشيخ د. محمد الأمين إسماعيل',
                        style: TextStyle(
                          color: AppColors.mainText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close,
                          color: AppColors.secondaryText, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(color: AppColors.cardGradientStart.withOpacity(0.4)),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BioParagraph(
                          'هو فضيلة الشيخ الداعية الدكتور محمد الأمين إسماعيل، أحد أبرز الدعاة والعلماء البارزين في السودان.',
                        ),
                        _BioParagraph(
                          'يحمل درجات علمية رفيعة في الشريعة الإسلامية والعقيدة، وعُرف بدروسه ومحاضراته المنهجية التي تلقى قبولاً واسعاً.',
                        ),
                        _BioParagraph(
                          'له إسهامات دعوية كبيرة داخل السودان وخارجه من خلال الخطب والمواعظ والبرامج التلفزيونية والإذاعية والدورات العلمية الموجهة لطلبة العلم وعامة المسلمين.',
                        ),
                        _BioParagraph(
                          'يتميز بأسلوبه العلمي الرصين وحرصه على نشر التوحيد والسنة والمنهج الوسطي المستقيم.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'إغلاق',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _BioParagraph extends StatelessWidget {
  final String text;
  const _BioParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '• $text',
        style: TextStyle(
          color: AppColors.lightText,
          fontSize: 12,
          height: 1.6,
        ),
      ),
    );
  }
}
