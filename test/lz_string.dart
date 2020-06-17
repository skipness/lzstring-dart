import 'package:test/test.dart';
import 'package:lzstring/lzstring.dart';

void main() async {
  final String input = "測試,测试,テスト,testing";
  final String normal = await LZString.compress(input);
  final String base64 = await LZString.compressToBase64(input);
  final String utf16 = await LZString.compressToUTF16(input);
  final String encodedUriComponent =
      await LZString.compressToEncodedURIComponent(input);
  final List<int> uint8Array = await LZString.compressToUint8Array(input);

  group('compress data', () {
    test('to normal', () {
      expect(normal, equals('贝ꌲ蠴贫梫텨挌觐젉蘰׀ꘆ煁Ⰷ恳 '));
    });

    test('to base 64', () {
      expect(base64, equals('jR2jMog0jStoq9FoYwyJ0MgJhjAFwKYGcUEsB2BzIA=='));
    });

    test('to utf 16', () {
      expect(utf16, equals('䚮棬儦䣲孥⽥僦಩梄ʁ䘠尪こ䔤堮悓ဠ '));
    });

    test('to encoded uri component', () {
      expect(encodedUriComponent,
          equals('jR2jMog0jStoq9FoYwyJ0MgJhjAFwKYGcUEsB2BzIA'));
    });

    test('to uint8 array', () {
      expect(
          uint8Array.toList(),
          equals([
            141,
            29,
            163,
            50,
            136,
            52,
            141,
            43,
            104,
            171,
            209,
            104,
            99,
            12,
            137,
            208,
            200,
            9,
            134,
            48,
            5,
            192,
            166,
            6,
            113,
            65,
            44,
            7,
            96,
            115,
            32,
            0
          ]));
    });
  });

  group('decompress data', () {
    test('from normal', () async {
      expect(await LZString.decompress(normal), equals(input));
    });

    test('from base 64', () async {
      expect(await LZString.decompressFromBase64(base64), equals(input));
    });

    test('from utf 16', () async {
      expect(await LZString.decompressFromUTF16(utf16), equals(input));
    });

    test('from encoded uri component', () async {
      expect(await LZString.decompressFromEncodedURIComponent(encodedUriComponent),
          equals(input));
    });

    test('from uint8 array', () async {
      expect(await LZString.decompressFromUint8Array(uint8Array), equals(input));
    });
  });
}
