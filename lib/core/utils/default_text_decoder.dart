import 'dart:convert';
import 'dart:typed_data';

import 'package:twake_previewer_flutter/core/constants/supported_charset.dart';
import 'package:twake_previewer_flutter/core/utils/text_decoder.dart';

class DefaultTextDecoder implements TextDecoder {
  const DefaultTextDecoder();

  /// Detects charset by scanning raw bytes — no String allocation, O(n) with
  /// early exit on first invalid byte. Checks UTF-8 BOM first for O(1) fast path.
  @override
  SupportedCharset detectCharset(Uint8List bytes) {
    try {
      if (bytes.isEmpty) return SupportedCharset.utf8;

      // Fast path: UTF-8 BOM (EF BB BF)
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        return SupportedCharset.utf8;
      }

      // Scan bytes to validate UTF-8 sequences without allocating a String.
      // Returns latin1 on first invalid byte so the previewer never throws.
      int i = 0;
      while (i < bytes.length) {
        final b = bytes[i];
        int trailing;
        if (b & 0x80 == 0) {
          i++;
          continue; // ASCII byte — valid
        } else if (b & 0xE0 == 0xC0) {
          trailing = 1;
        } else if (b & 0xF0 == 0xE0) {
          trailing = 2;
        } else if (b & 0xF8 == 0xF0) {
          trailing = 3;
        } else {
          return SupportedCharset.latin1; // Invalid lead byte
        }
        i++;
        for (int j = 0; j < trailing; j++, i++) {
          if (i >= bytes.length || (bytes[i] & 0xC0) != 0x80) {
            return SupportedCharset.latin1; // Missing/invalid continuation byte
          }
        }
      }
      return SupportedCharset.utf8;
    } catch (_) {
      return SupportedCharset.latin1;
    }
  }

  @override
  String decode({required Uint8List bytes, required SupportedCharset charset}) {
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
