import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/favorites_service.dart';
import '../services/downloads_service.dart';
import '../services/archive_service.dart';
import 'sheikh_bio_dialog.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _clearing = false;

  Future<void> _clearCache() async {
    setState(() => _clearing = true);
    await ArchiveService.clearCache();
    if (!mounted) return;
    setState(() => _clearing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primaryTeal.withOpacity(0.3)),
        ),
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 8),
            const Text(
              'تم محو الذاكرة المؤقتة',
              style: TextStyle(color: AppColors.mainText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService.instance;
    final downloadsService = DownloadsService.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardDark,
              border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.4), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.person,
                size: 64, color: AppColors.primaryTeal.withOpacity(0.6)),
          ),
        ),
        const SizedBox(height: 28),

        // من هو الشيخ
        _SettingsCard(
          child: _SettingsItem(
            title: 'من هو الشيخ د. محمد الأمين إسماعيل',
            icon: Icons.info_outline,
            onTap: () => showSheikhBioDialog(context),
          ),
        ),
        const SizedBox(height: 14),

        // محو الكاش
        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'محو ذاكرة التخزين المؤقت',
                        style: TextStyle(
                          color: AppColors.mainText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'لفتح أسرع حتى مع ضعف الإنترنت، يحتفظ التطبيق بآخر نسخة من المحاضرات. امسحها فقط إذا أضيفت محاضرات جديدة ولم تظهر بعد.',
                        style: TextStyle(
                          color: AppColors.secondaryText.withOpacity(0.8),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _clearing ? null : _clearCache,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: _clearing
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryTeal,
                            ),
                          )
                        : Icon(Icons.delete_sweep_outlined,
                            color: AppColors.primaryTeal, size: 26),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // الإحصائيات
        Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: favoritesService,
                builder: (context, _) => _StatCard(
                  label: 'المفضلة',
                  value: favoritesService.favorites.length.toString(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AnimatedBuilder(
                animation: downloadsService,
                builder: (context, _) => _StatCard(
                  label: 'التنزيلات',
                  value: downloadsService.downloads.length.toString(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        Center(
          child: Column(
            children: [
              Text(
                'تطوير',
                style: TextStyle(
                  color: AppColors.mainText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'علاء الدين خضر',
                style: TextStyle(
                  color: AppColors.mainText,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'تواصل معي',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    icon: Icons.chat,
                    color: const Color(0xFF25D366),
                  ),
                  const SizedBox(width: 18),
                  _SocialButton(
                    icon: Icons.facebook,
                    color: const Color(0xFF1877F2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGradientStart.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<_SettingsItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _pressed ? const Color(0xFF165652) : Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.mainText,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(widget.icon, color: AppColors.primaryTeal, size: 22),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGradientStart.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.mainText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SocialButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
