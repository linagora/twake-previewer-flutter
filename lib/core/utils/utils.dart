import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class Utils {
  const Utils._();

  static final Random _random = Random.secure();

  static String getRandString(int len) {
    var values = Uint8List.fromList(
      List.generate(len, (_) => _random.nextInt(256)),
    );
    return base64UrlEncode(values).substring(0, len);
  }

  static void handleEscapeKey(KeyEvent event, VoidCallback? onClose) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      onClose?.call();
    }
  }
}
