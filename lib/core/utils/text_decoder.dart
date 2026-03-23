import 'dart:convert';
import 'dart:typed_data';

import '../constants/supported_charset.dart';

class TextDecoder {
  const TextDecoder();

  String decode({
    required Uint8List bytes,
    required SupportedCharset charset,
  }) {
    switch (charset) {
      case SupportedCharset.ascii:
        return _decodeAscii(bytes);
      case SupportedCharset.latin1:
        return _decodeLatin1(bytes);
      case SupportedCharset.utf8:
        return _decodeUtf8(bytes);
    }
  }

  String _decodeUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
  }

  String _decodeAscii(Uint8List bytes) {
    try {
      return ascii.decode(bytes);
    } catch (_) {
      try {
        return _decodeLatin1(bytes);
      } catch (_) {
        return ascii.decode(bytes, allowInvalid: true);
      }
    }
  }

  String _decodeLatin1(Uint8List bytes) {
    return latin1.decode(bytes);
  }
}
