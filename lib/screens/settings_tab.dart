import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cache_service.dart';
import '../theme/app_colors.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  static const Color _gold = Color(0xFFD6B56E);

  bool _clearing = false;
  double _clearProgress = 0;

  Future<void> _clearCache() async {
    if (_clearing) return;

    setState(() {
      _clearing = true;
      _clearProgress = 0;
    });

    try {
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 80));

        if (!mounted) return;

        setState(() {
          _clearProgress = i / 10;
        });
      }

      await CacheService.clearCache();

      if (!mounted) return;

      setState(() {
        _clearing = false;
        _clearProgress = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تنظيف الملفات المؤقتة بنجاح'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _clearing = false;
        _clearProgress = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تنظيف الملفات المؤقتة'),
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/message/YK3PTTIVY4IOP1',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _openFacebook() async {
    final uri = Uri.parse(
      'https://www.facebook.com/profile.php?id=100065331340861',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'تطبيق الشيخ د. محمد الأمين إسماعيل',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryDarkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الإعدادات',
          style: TextStyle(
            color: AppColors.mainText,
            fontWeight: FontWeight.w900,
            fontSize: 21,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _gold.withOpacity(0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'الشيخ د. محمد الأمين إسماعيل',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mainText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيق المحاضرات والدروس',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'تطبيق يتيح لك الاستماع إلى محاضرات الشيخ '
                    'د. محمد الأمين إسماعيل وتنزيلها للاستماع '
                    'إليها دون اتصال بالإنترنت.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      height: 1.7,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _SettingsItem(
              icon: Icons.share_outlined,
              title: 'مشاركة التطبيق',
              onTap: _shareApp,
            ),

            const SizedBox(height: 10),

            _SettingsItem(
              icon: Icons.delete_outline,
              title: _clearing
                  ? 'جاري تنظيف الملفات...'
                  : 'تنظيف الملفات المؤقتة',
              onTap: _clearing ? null : _clearCache,
              trailing: _clearing
                  ? SizedBox(
                      width: 30,
                      height: 30,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _clearProgress,
                            strokeWidth: 2.5,
                            color: _gold,
                          ),
                          Text(
                            '${(_clearProgress * 100).round()}',
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 28),

            Text(
              'تواصل مع الشيخ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mainText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    icon: Icons.chat,
                    title: 'واتساب',
                    onTap: _openWhatsApp,
                    iconColor: const Color(0xFF25D366),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    icon: Icons.facebook,
                    title: 'فيسبوك',
                    onTap: _openFacebook,
                    iconColor: const Color(0xFF1877F2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'مراسلة علاء الدين للتصميم عبر واتساب',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'تطوير',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'علاء الدين خضر',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Developed by Alaa Al-Din Khader',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<_SettingsItem> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD6B56E).withOpacity(0.14),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: const Color(0xFFD6B56E),
                size: 23,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.mainText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;

  const _SocialButton({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.iconColor.withOpacity(0.18),
            ),
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                color: widget.iconColor,
                size: 28,
              ),
              const SizedBox(height: 7),
              Text(
                widget.title,
                style: TextStyle(
                  color: AppColors.mainText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
