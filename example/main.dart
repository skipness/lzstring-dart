import 'package:lzstring/lzstring.dart';

void main() { 
  String input = "Dart implemntation of lz-string";
  print('Input: $input');
  print('Compressed String: ${LZString.compress(input)}');
  print('Compressed Base 64 String: ${LZString.compressToBase64(input)}');
  print('Compressed UTF16 String: ${LZString.compressToUTF16(input)}');
  print(
      'Compressed Encoded URI Component: ${LZString.compressToEncodedURIComponent(input)}');
  print('Compressed Uint8 Array: ${LZString.compressToUint8Array(input)}');
}
