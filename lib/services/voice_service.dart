import 'package:flutter/foundation.dart';

class VoiceService {
  Future<void> speak(String text) async {
    if (kIsWeb) return;
    debugPrint('Voice output: $text');
  }
}
