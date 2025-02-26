import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class Utils {
  const Utils._();

  static final Random _random = Random.secure();

  static String getRandString(int len) {
    var values = Uint8List.fromList(
      List.generate(len, (_) => _random.nextInt(256)),
    );
    return base64UrlEncode(values).substring(0, len);
  }
}
