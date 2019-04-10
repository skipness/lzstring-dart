library lzstring;

import 'dart:math';
import 'dart:typed_data';

typedef String GetCharFromInt(int a);
typedef int GetNextValue(int index);

class _Data {
  int value, position, index;
  _Data(this.value, this.position, this.index);
}

class LZString {
  static String _keyStrBase64 =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
  static String _keyStrUriSafe =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-\$";
  static Map<String, Map<String, int>> _baseReverseDic =
      Map<String, Map<String, int>>();

  static int _getBaseValue(String alphabet, String character) {
    if (!_baseReverseDic.containsKey(alphabet)) {
      _baseReverseDic[alphabet] = Map<String, int>();
      for (int i = 0; i < alphabet.length; i++) {
        _baseReverseDic[alphabet][alphabet[i]] = i;
      }
    }
    return _baseReverseDic[alphabet][character];
  }

  /**
   * Produces ASCII UTF-16 strings representing the original string encoded in Base64 from [input].
   * 
   * Can be decompressed with `decompressFromBase64`. 
   * 
   * This works by using only 6bits of storage per character. The strings produced are therefore 166% bigger than those produced by `compress`.
   */
  static String compressToBase64(String input) {
    if (input == null) return "";
    String res = _compress(input, 6, (a) => _keyStrBase64[a]);
    switch (res.length % 4) {
      case 0:
        return res;
      case 1:
        return res + "===";
      case 2:
        return res + "==";
      case 3:
        return res + "=";
    }
    return null;
  }

  /**
   * Decompress base64 [input] which produces by `compressToBase64`.
   */
  static String decompressFromBase64(String input) {
    if (input == null) return "";
    if (input == "") return null;
    return _decompress(input.length, 32,
        (index) => _getBaseValue(_keyStrBase64, input[index]));
  }

  /**
   * Produces "valid" UTF-16 strings from [input].
   * 
   * Can be decompressed with `decompressFromUTF16`. 
   * 
   * This works by using only 15 bits of storage per character. The strings produced are therefore 6.66% bigger than those produced by `compress`.
   */
  static String compressToUTF16(String input) {
    if (input == null) return "";
    return _compress(input, 15, (a) => String.fromCharCode(a + 32)) + " ";
  }

  /**
   * Decompress "valid" UTF-16 string which produces by `compressToUTF16`
   */
  static String decompressFromUTF16(String compressed) {
    if (compressed == null) return "";
    if (compressed == "") return null;
    return _decompress(
        compressed.length, 16384, (index) => compressed.codeUnitAt(index) - 32);
  }

  /**
   * Produces an uint8Array.
   * 
   * Can be decompressed with `decompressFromUint8Array`
   */
  static Uint8List compressToUint8Array(String uncompressed) {
    String compressed = compress(uncompressed);
    Uint8List buf = Uint8List(compressed.length * 2);
    for (var i = 0, totalLen = compressed.length; i < totalLen; i++) {
      int currentValue = compressed.codeUnitAt(i);
      buf[i * 2] = currentValue >> 8;
      buf[i * 2 + 1] = currentValue % 256;
    }
    return buf;
  }

  /**
   * Decompress uint8Array which produces by `compressToUint8Array`.
   */
  static String decompressFromUint8Array(Uint8List compressed) {
    if (compressed == null) {
      return "";
    } else {
      List<int> buf = List<int>(compressed.length ~/ 2);
      for (var i = 0, totalLen = buf.length; i < totalLen; i++) {
        buf[i] = compressed[i * 2] * 256 + compressed[i * 2 + 1];
      }
      List<String> result = List<String>();
      buf.forEach((c) => result.add(String.fromCharCode(c)));
      return decompress(result.join(''));
    }
  }

  /**
   * Decompress ASCII strings [input] which produces by `compressToEncodedURIComponent`.
   */
  static String decompressFromEncodedURIComponent(String input) {
    if (input == null) return "";
    if (input == "") return null;
    input = input.replaceAll(' ', '+');
    return _decompress(input.length, 32,
        (index) => _getBaseValue(_keyStrUriSafe, input[index]));
  }

  /**
   * Produces ASCII strings representing the original string encoded in Base64 with a few tweaks to make these URI safe.
   * 
   * Can be decompressed with `decompressFromEncodedURIComponent`
   */
  static String compressToEncodedURIComponent(String input) {
    if (input == null) return "";
    return _compress(input, 6, (a) => _keyStrUriSafe[a]);
  }

  /**
   * Produces invalid UTF-16 strings from [uncompressed].
   * 
   * Can be decompressed with `decompress`.
   */
  static String compress(final String uncompressed) {
    return _compress(uncompressed, 16, (a) => String.fromCharCode(a));
  }

  static String _compress(
      String uncompressed, int bitsPerChar, GetCharFromInt getCharFromInt) {
    if (uncompressed == null) return "";
    int i, value;
    Map<String, int> contextDictionary = Map<String, int>();
    Map<String, bool> contextDictionaryToCreate = Map<String, bool>();
    String contextC = "";
    String contextWC = "";
    String contextW = "";
    int contextEnlargeIn =
        2; // Compensate for the first entry which should not count
    int contextDictSize = 3;
    int contextNumBits = 2;
    StringBuffer contextData = StringBuffer();
    int contextDataVal = 0;
    int contextDataPosition = 0;
    int ii;

    for (ii = 0; ii < uncompressed.length; ii++) {
      contextC = uncompressed[ii];
      if (!contextDictionary.containsKey(contextC)) {
        contextDictionary[contextC] = contextDictSize++;
        contextDictionaryToCreate[contextC] = true;
      }

      contextWC = contextW + contextC;
      if (contextDictionary.containsKey(contextWC)) {
        contextW = contextWC;
      } else {
        if (contextDictionaryToCreate.containsKey(contextW)) {
          if (contextW.codeUnitAt(0) < 256) {
            for (i = 0; i < contextNumBits; i++) {
              contextDataVal = (contextDataVal << 1);
              if (contextDataPosition == bitsPerChar - 1) {
                contextDataPosition = 0;
                contextData.write(getCharFromInt(contextDataVal));
                contextDataVal = 0;
              } else {
                contextDataPosition++;
              }
            }
            value = contextW.codeUnitAt(0);
            for (i = 0; i < 8; i++) {
              contextDataVal = (contextDataVal << 1) | (value & 1);
              if (contextDataPosition == bitsPerChar - 1) {
                contextDataPosition = 0;
                contextData.write(getCharFromInt(contextDataVal));
                contextDataVal = 0;
              } else {
                contextDataPosition++;
              }
              value = value >> 1;
            }
          } else {
            value = 1;
            for (i = 0; i < contextNumBits; i++) {
              contextDataVal = (contextDataVal << 1) | value;
              if (contextDataPosition == bitsPerChar - 1) {
                contextDataPosition = 0;
                contextData.write(getCharFromInt(contextDataVal));
                contextDataVal = 0;
              } else {
                contextDataPosition++;
              }
              value = 0;
            }
            value = contextW.codeUnitAt(0);
            for (i = 0; i < 16; i++) {
              contextDataVal = (contextDataVal << 1) | (value & 1);
              if (contextDataPosition == bitsPerChar - 1) {
                contextDataPosition = 0;
                contextData.write(getCharFromInt(contextDataVal));
                contextDataVal = 0;
              } else {
                contextDataPosition++;
              }
              value = value >> 1;
            }
          }
          contextEnlargeIn--;
          if (contextEnlargeIn == 0) {
            contextEnlargeIn = pow(2, contextNumBits);
            contextNumBits++;
          }
          contextDictionaryToCreate.remove(contextW);
        } else {
          value = contextDictionary[contextW];
          for (i = 0; i < contextNumBits; i++) {
            contextDataVal = (contextDataVal << 1) | (value & 1);
            if (contextDataPosition == bitsPerChar - 1) {
              contextDataPosition = 0;
              contextData.write(getCharFromInt(contextDataVal));
              contextDataVal = 0;
            } else {
              contextDataPosition++;
            }
            value = value >> 1;
          }
        }
        contextEnlargeIn--;
        if (contextEnlargeIn == 0) {
          contextEnlargeIn = pow(2, contextNumBits);
          contextNumBits++;
        }
        // Add wc to the dictionary.
        contextDictionary[contextWC] = contextDictSize++;
        contextW = contextC;
      }
    }

    // Output the code for w.
    if (contextW != "") {
      if (contextDictionaryToCreate.containsKey(contextW)) {
        if (contextW.codeUnitAt(0) < 256) {
          for (i = 0; i < contextNumBits; i++) {
            contextDataVal = (contextDataVal << 1);
            if (contextDataPosition == bitsPerChar - 1) {
              contextDataPosition = 0;
              contextData.write(getCharFromInt(contextDataVal));
              contextDataVal = 0;
            } else {
              contextDataPosition++;
            }
          }
          value = contextW.codeUnitAt(0);
          for (i = 0; i < 8; i++) {
            contextDataVal = (contextDataVal << 1) | (value & 1);
            if (contextDataPosition == bitsPerChar - 1) {
              contextDataPosition = 0;
              contextData.write(getCharFromInt(contextDataVal));
              contextDataVal = 0;
            } else {
              contextDataPosition++;
            }
            value = value >> 1;
          }
        } else {
          value = 1;
          for (i = 0; i < contextNumBits; i++) {
            contextDataVal = (contextDataVal << 1) | value;
            if (contextDataPosition == bitsPerChar - 1) {
              contextDataPosition = 0;
              contextData.write(getCharFromInt(contextDataVal));
              contextDataVal = 0;
            } else {
              contextDataPosition++;
            }
            value = 0;
          }
          value = contextW.codeUnitAt(0);
          for (i = 0; i < 16; i++) {
            contextDataVal = (contextDataVal << 1) | (value & 1);
            if (contextDataPosition == bitsPerChar - 1) {
              contextDataPosition = 0;
              contextData.write(getCharFromInt(contextDataVal));
              contextDataVal = 0;
            } else {
              contextDataPosition++;
            }
            value = value >> 1;
          }
        }
        contextEnlargeIn--;
        if (contextEnlargeIn == 0) {
          contextEnlargeIn = pow(2, contextNumBits);
          contextNumBits++;
        }
        contextDictionaryToCreate.remove(contextW);
      } else {
        value = contextDictionary[contextW];
        for (i = 0; i < contextNumBits; i++) {
          contextDataVal = (contextDataVal << 1) | (value & 1);
          if (contextDataPosition == bitsPerChar - 1) {
            contextDataPosition = 0;
            contextData.write(getCharFromInt(contextDataVal));
            contextDataVal = 0;
          } else {
            contextDataPosition++;
          }
          value = value >> 1;
        }
      }
      contextEnlargeIn--;
      if (contextEnlargeIn == 0) {
        contextEnlargeIn = pow(2, contextNumBits);
        contextNumBits++;
      }
    }

    // Mark the end of the stream
    value = 2;
    for (i = 0; i < contextNumBits; i++) {
      contextDataVal = (contextDataVal << 1) | (value & 1);
      if (contextDataPosition == bitsPerChar - 1) {
        contextDataPosition = 0;
        contextData.write(getCharFromInt(contextDataVal));
        contextDataVal = 0;
      } else {
        contextDataPosition++;
      }
      value = value >> 1;
    }

    // Flush the last char
    while (true) {
      contextDataVal = (contextDataVal << 1);
      if (contextDataPosition == bitsPerChar - 1) {
        contextData.write(getCharFromInt(contextDataVal));
        break;
      } else
        contextDataPosition++;
    }
    return contextData.toString();
  }

  /**
   * Decompress invalid UTF-16 strings which produces by `compress`.
   */
  static String decompress(final String compressed) {
    if (compressed == null) return "";
    if (compressed.isEmpty) return null;
    return LZString._decompress(
        compressed.length, 32768, (index) => compressed.codeUnitAt(index));
  }

  static String _decompress(
      int length, int resetValue, GetNextValue getNextValue) {
    Map<int, String> dictionary = Map<int, String>();
    int enLargeIn = 4,
        dictSize = 4,
        numBits = 3,
        i,
        bits,
        maxpower,
        next,
        power,
        resb;
    String entry = "", c, w;
    StringBuffer result = StringBuffer();
    _Data data = _Data(getNextValue(0), resetValue, 1);

    for (i = 0; i < 3; i++) {
      dictionary[i] = i.toString();
    }

    bits = 0;
    maxpower = pow(2, 2);
    power = 1;
    while (power != maxpower) {
      resb = data.value & data.position;
      data.position >>= 1;
      if (data.position == 0) {
        data.position = resetValue;
        data.value = getNextValue(data.index++);
      }
      bits |= (resb > 0 ? 1 : 0) * power;
      power <<= 1;
    }

    switch (next = bits) {
      case 0:
        bits = 0;
        maxpower = pow(2, 8);
        power = 1;
        while (power != maxpower) {
          resb = data.value & data.position;
          data.position >>= 1;
          if (data.position == 0) {
            data.position = resetValue;
            data.value = getNextValue(data.index++);
          }
          bits |= (resb > 0 ? 1 : 0) * power;
          power <<= 1;
        }
        c = String.fromCharCode(bits);
        break;
      case 1:
        bits = 0;
        maxpower = pow(2, 16);
        power = 1;
        while (power != maxpower) {
          resb = data.value & data.position;
          data.position >>= 1;
          if (data.position == 0) {
            data.position = resetValue;
            data.value = getNextValue(data.index++);
          }
          bits |= (resb > 0 ? 1 : 0) * power;
          power <<= 1;
        }
        c = String.fromCharCode(bits);
        break;
      case 2:
        return "";
    }
    dictionary[3] = c;
    w = c;
    result.write(c);
    while (true) {
      if (data.index > length) return "";
      bits = 0;
      maxpower = pow(2, numBits);
      power = 1;
      while (power != maxpower) {
        resb = data.value & data.position;
        data.position >>= 1;
        if (data.position == 0) {
          data.position = resetValue;
          data.value = getNextValue(data.index++);
        }
        bits |= (resb > 0 ? 1 : 0) * power;
        power <<= 1;
      }

      int cc;
      switch (cc = bits) {
        case 0:
          bits = 0;
          maxpower = pow(2, 8);
          power = 1;
          while (power != maxpower) {
            resb = data.value & data.position;
            data.position >>= 1;
            if (data.position == 0) {
              data.position = resetValue;
              data.value = getNextValue(data.index++);
            }
            bits |= (resb > 0 ? 1 : 0) * power;
            power <<= 1;
          }
          dictionary[dictSize++] = String.fromCharCode(bits);
          cc = dictSize - 1;
          enLargeIn--;
          break;
        case 1:
          bits = 0;
          maxpower = pow(2, 16);
          power = 1;
          while (power != maxpower) {
            resb = data.value & data.position;
            data.position >>= 1;
            if (data.position == 0) {
              data.position = resetValue;
              data.value = getNextValue(data.index++);
            }
            bits |= (resb > 0 ? 1 : 0) * power;
            power <<= 1;
          }
          dictionary[dictSize++] = String.fromCharCode(bits);
          cc = dictSize - 1;
          enLargeIn--;
          break;
        case 2:
          return result.toString();
      }

      if (enLargeIn == 0) {
        enLargeIn = pow(2, numBits);
        numBits++;
      }

      if (cc < dictionary.length && dictionary.containsKey(cc)) {
        entry = dictionary[cc];
      } else {
        if (cc == dictSize) {
          entry = w + w[0];
        } else
          return null;
      }
      result.write(entry);

      // Add w+entry[0] to the dictionary.
      dictionary[dictSize++] = w + entry[0];
      enLargeIn--;

      w = entry;

      if (enLargeIn == 0) {
        enLargeIn = pow(2, numBits);
        numBits++;
      }
    }
  }
}
