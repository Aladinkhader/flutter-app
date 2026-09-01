import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/audio_player_service.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('سجل التشخيص',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: DebugLog.entries.isEmpty
            ? const Center(
                child: Text(
                  'لا يوجد سجل بعد.\nشغّل محاضرة ثم ارجع هنا واضغط تحديث.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: DebugLog.entries.length,
                itemBuilder: (context, index) {
                  final entry =
                      DebugLog.entries[DebugLog.entries.length - 1 - index];
                  final isError = entry.contains('ERROR');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SelectableText(
                      entry,
                      style: TextStyle(
                        color: isError ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
