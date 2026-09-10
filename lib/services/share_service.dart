import 'package:share_plus/share_plus.dart';

import '../models/lecture.dart';

class ShareService {
  ShareService._();

  static Future<void> shareLecture(Lecture lecture) async {
    final text =
        '🎙️ ${lecture.title}\n\n'
        'الشيخ د. محمد الأمين إسماعيل\n\n'
        'استمع إلى المحاضرة:\n'
        '${lecture.audioUrl}';

    await Share.share(
      text,
      subject: lecture.title,
    );
  }
}
