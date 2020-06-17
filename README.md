# lzstring
[![Pub](https://img.shields.io/badge/pub-v1.0.2%2B1-blue.svg)](https://pub.dartlang.org/packages/lzstring)

Dart implementation of lz-string compression algorithm

The original JavaScript version is [here](https://github.com/pieroxy/lz-string)

## Usage
```dart
Future<String> compressedString = LZString.compress('Some String');
Future<String> decompressedString = LZString.decompress(compressedString);
```
For more usage, please read the exapmle in [example](https://github.com/skipness/lzstring-dart/tree/master/example) folder

## Running test
```
pub run test test/lz_string.dart
```
