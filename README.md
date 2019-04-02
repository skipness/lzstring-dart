# lzstring_dart
Dart implementation of lz-string compression algorithm

The original JavaScript version is [here](https://github.com/pieroxy/lz-string)

## Usage
```dart
String compressedString = LZString.compress('Some String');
String decompressedString = LZString.decompress(compressedString);
```
For more usage, please read the exapmle in [example](https://github.com/skipness/lzstring-dart/tree/master/example) folder

## Running test
```
pub run test test/lz_string_test.dart
```