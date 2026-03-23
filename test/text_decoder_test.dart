import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_previewer_flutter/core/constants/supported_charset.dart';
import 'package:twake_previewer_flutter/core/utils/default_text_decoder.dart';

void main() {
  const decoder = DefaultTextDecoder();

  group('TextDecoder - UTF8', () {
    test('decode valid utf8', () {
      final bytes = Uint8List.fromList(utf8.encode('hello'));

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      expect(result, 'hello');
    });

    test('decode utf8 multi-byte characters', () {
      final bytes = Uint8List.fromList(utf8.encode('Xin chào 🌍'));

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      expect(result, 'Xin chào 🌍');
    });

    test('decode malformed utf8 falls back to latin1 (no replacement char)',
        () {
      final bytes = Uint8List.fromList([0xC3, 0x28]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      final latin1Result = latin1.decode(bytes);

      expect(result, latin1Result);
      expect(result.contains('�'), false);
    });

    test('decode badly malformed utf8 still returns latin1 result', () {
      final bytes = Uint8List.fromList([0xE2, 0x28, 0xA1]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      expect(result, latin1.decode(bytes));
    });

    test('utf8 mixed valid and invalid bytes prefers latin1 fallback', () {
      final bytes = Uint8List.fromList([
        ...utf8.encode('Hello '),
        0xC3,
        0x28,
        ...utf8.encode(' World'),
      ]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      expect(result, latin1.decode(bytes));
    });

    test('utf8 decode is idempotent for valid input', () {
      const original = 'Hello UTF8 🌍';
      final bytes = Uint8List.fromList(utf8.encode(original));

      final decoded = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      final reEncoded = Uint8List.fromList(utf8.encode(decoded));

      expect(decoded, original);
      expect(reEncoded, bytes);
    });

    test('decode empty bytes', () {
      final result = decoder.decode(
        bytes: Uint8List(0),
        charset: SupportedCharset.utf8,
      );

      expect(result, '');
    });

    test('decode single byte', () {
      final bytes = Uint8List.fromList([0x41]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      expect(result, 'A');
    });

    test('decode large input does not crash', () {
      final bytes = Uint8List.fromList(List.generate(10000, (i) => i % 256));

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      expect(result, isA<String>());
    });

    test('decode is deterministic', () {
      final bytes = Uint8List.fromList([0xC3, 0x28]);

      final r1 = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      final r2 = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      expect(r1, r2);
    });
  });

  group('TextDecoder - ASCII', () {
    test('decode valid ascii', () {
      final bytes = Uint8List.fromList([65, 66, 67]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.ascii,
      );

      expect(result, 'ABC');
    });

    test('decode ascii with invalid byte falls back to latin1', () {
      final bytes = Uint8List.fromList([0x41, 0xFF]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.ascii,
      );

      expect(result, latin1.decode(bytes));
    });

    test('ascii fallback matches latin1 output exactly', () {
      final bytes = Uint8List.fromList([0x80, 0xFF]);

      final asciiResult = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.ascii,
      );

      final latin1Result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.latin1,
      );

      expect(asciiResult, latin1Result);
    });

    test('decode ascii boundary values', () {
      final bytes = Uint8List.fromList([0x00, 0x7F]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.ascii,
      );

      expect(result.length, 2);
    });
  });

  group('TextDecoder - Latin1', () {
    test('decode latin1 always works', () {
      final bytes = Uint8List.fromList([0xFF]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.latin1,
      );

      expect(result, latin1.decode(bytes));
    });

    test('decode latin1 extended characters', () {
      final bytes = Uint8List.fromList([0xC0, 0xD1, 0xE9]);

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.latin1,
      );

      expect(result, 'ÀÑé');
    });

    test('decode latin1 full range', () {
      final bytes = Uint8List.fromList(List.generate(256, (i) => i));

      final result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.latin1,
      );

      expect(result.length, 256);
    });
  });

  group('TextDecoder - Cross charset behavior', () {
    test('utf8 malformed equals latin1 result', () {
      final bytes = Uint8List.fromList([0xE9]);

      final utf8Result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.utf8,
      );

      final latin1Result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.latin1,
      );

      expect(utf8Result, latin1Result);
    });

    test('ascii vs latin1 with extended bytes', () {
      final bytes = Uint8List.fromList([0x80, 0xFF]);

      final asciiResult = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.ascii,
      );

      final latin1Result = decoder.decode(
        bytes: bytes,
        charset: SupportedCharset.latin1,
      );

      expect(asciiResult, latin1Result);
    });
  });

  group('TextDecoder - detectCharset', () {
    test('empty bytes → utf8', () {
      final result = decoder.detectCharset(Uint8List(0));
      expect(result, SupportedCharset.utf8);
    });

    test('UTF-8 BOM → utf8', () {
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, 0x61]);
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.utf8);
    });

    test('ASCII → utf8', () {
      final bytes = Uint8List.fromList('Hello World'.codeUnits);
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.utf8);
    });

    test('valid 2-byte UTF-8 → utf8', () {
      final bytes = Uint8List.fromList([0xC3, 0xA9]); // é
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.utf8);
    });

    test('valid 3-byte UTF-8 → utf8', () {
      final bytes = Uint8List.fromList([0xE2, 0x82, 0xAC]); // €
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.utf8);
    });

    test('valid 4-byte UTF-8 → utf8', () {
      final bytes = Uint8List.fromList([0xF0, 0x9F, 0x98, 0x84]); // 😄
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.utf8);
    });

    test('invalid leading byte → latin1', () {
      final bytes = Uint8List.fromList([0xFF]);
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.latin1);
    });

    test('incomplete multi-byte sequence → latin1', () {
      final bytes = Uint8List.fromList([0xE2, 0x82]); // thiếu 1 byte
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.latin1);
    });

    test('invalid continuation byte → latin1', () {
      final bytes = Uint8List.fromList([0xE2, 0x28, 0xA1]);
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.latin1);
    });

    test('mixed ASCII + UTF-8 → utf8', () {
      final bytes = Uint8List.fromList([
        ...'Hello '.codeUnits,
        0xF0,
        0x9F,
        0x98,
        0x84,
      ]);
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.utf8);
    });

    test('invalid byte in middle → latin1 (early exit)', () {
      final bytes = Uint8List.fromList([
        0x61,
        0x62,
        0xFF,
        0x63,
      ]);
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.latin1);
    });

    test('standalone continuation byte → latin1', () {
      final bytes = Uint8List.fromList([0x80]);
      final result = decoder.detectCharset(bytes);
      expect(result, SupportedCharset.latin1);
    });

    test('valid UTF-8 encoded vietnamese text → utf8', () {
      const text = 'Xin chào Việt Nam';
      final bytes = Uint8List.fromList(utf8.encode(text));

      final result = decoder.detectCharset(bytes);

      expect(result, SupportedCharset.utf8);
    });

    test('UTF-16 codeUnits should NOT be detected as utf8', () {
      const text = 'Xin chào';
      final bytes = Uint8List.fromList(text.codeUnits);

      final result = decoder.detectCharset(bytes);

      expect(result, isNot(SupportedCharset.utf8));
    });
  });
}
