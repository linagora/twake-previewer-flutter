import 'dart:typed_data';

import 'package:twake_previewer_flutter/core/constants/supported_charset.dart';

abstract class TextDecoder {
  SupportedCharset detectCharset(Uint8List bytes);

  String decode({required Uint8List bytes, required SupportedCharset charset});
}
