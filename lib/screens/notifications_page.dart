import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.library_music_rounded,
        'title': 'محاضرات جديدة',
        'message': 'تمت إضافة محاضرات جديدة للشيخ د. محمد الأمين إسماعيل.',
        'time': 'جديد',
      },
      {
        'icon': Icons.notifications_active_rounded,
        'title': 'مرحبًا بك',
        'message': 'استمتع بالاستماع إلى مكتبة المحاضرات في أي وقت.',
        'time': 'اليوم',
      },
      {
        'icon': Icons.system_update_rounded,
        'title': 'تحديث التطبيق',
        'message': 'تابع التحديثات القادمة لتحصل على المزيد من المميزات.',
        'time': 'اليوم',
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'الإشعارات',
            style: GoogleFonts.tajawal(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.mainText,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.mainText,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: notifications.isEmpty
            ? _EmptyNotifications()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24,
                ),
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = notifications[index];

                  return _NotificationCard(
                    icon: notification['icon'] as IconData,
                    title: notification['title'] as String,
                    message: notification['message'] as String,
                    time: notification['time'] as String,
                  );
                },
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardGradientStart.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryTeal.withOpacity(0.12),
              border: Border.all(
                color: AppColors.primaryTeal.withOpacity(0.35),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainText,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.tajawal(
                        fontSize: 9,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    height: 1.6,
                    color: AppColors.secondaryText,
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

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 70,
            color: AppColors.secondaryText.withOpacity(0.5),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد إشعارات',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.mainText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ستظهر الإشعارات الجديدة هنا',
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
