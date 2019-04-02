import 'package:test/test.dart';
import 'package:lzstring/lzstring.dart';

void main() {
  final String input = 'String for testing';
  final String normal = LZString.compress(input);
  final String base64 = LZString.compressToBase64(input);
  final String utf16 = LZString.compressToUTF16(input);
  final String encodedUriComponent =
      LZString.compressToEncodedURIComponent(input);
  final List<int> uint8Array = LZString.compressToUint8Array(input);

  group('compress data', () {
    test('to normal', () {
      expect(normal, equals('㊁灎ॠ瘎怄̰㶘頙쓑退'));
    });

    test('to base 64', () {
      expect(base64, equals('MoFwTglgdg5gBAMwPZjiApgZxNGQ'));
    });

    test('to utf 16', () {
      expect(utf16, equals('ᥠ尳䅌ހ猠ာ悛ᤂŬڑᩒ  '));
    });

    test('to encoded uri component', () {
      expect(encodedUriComponent, equals('MoFwTglgdg5gBAMwPZjiApgZxNGQ'));
    });

    test('to uint8 array', () {
      expect(
          uint8Array.toList(),
          equals([
            50,
            129,
            112,
            78,
            9,
            96,
            118,
            14,
            96,
            4,
            3,
            48,
            61,
            152,
            226,
            2,
            152,
            25,
            196,
            209,
            144,
            0
          ]));
    });
  });

  group('decompress data', () {
    test('from normal', () {
      expect(LZString.decompress(normal), equals(input));
    });

    test('from base 64', () {
      expect(LZString.decompressFromBase64(base64), equals(input));
    });

    test('from utf 16', () {
      expect(LZString.decompressFromUTF16(utf16), equals(input));
    });

    test('from encoded uri component', () {
      expect(LZString.decompressFromEncodedURIComponent(encodedUriComponent),
          equals(input));
    });

    test('from uint8 array', () {
      expect(LZString.decompressFromUint8Array(uint8Array), equals(input));
    });
  });
}
