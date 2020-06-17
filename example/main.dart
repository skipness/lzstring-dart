import 'package:lzstring/lzstring.dart';

void main() async { 
  String input = "Dart implemntation of lz-string";
  print('Input: $input');
  print('Compressed String: ${await LZString.compress(input)}');
  print('Compressed Base 64 String: ${await LZString.compressToBase64(input)}');
  print('Compressed UTF16 String: ${await LZString.compressToUTF16(input)}');
  print(
      'Compressed Encoded URI Component: ${await LZString.compressToEncodedURIComponent(input)}');
  print('Compressed Uint8 Array: ${await LZString.compressToUint8Array(input)}');
}
