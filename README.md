# lzstring
[![Pub](https://img.shields.io/badge/pub-v1.0.1%2B2-blue.svg)](https://pub.dartlang.org/packages/lzstring)

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
pub run test test/lz_string.dart
```
