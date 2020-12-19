import 'dart:convert';

import 'package:archive/archive.dart';

class Buffer {
  final StringBuffer buffer;
  final String lookupCharacters;
  final String lookupCharacters2;
  final wordCharacters;
  final prefixCharacters;
  final specialCharacters;
  final int quickLookupSize;

  // Character that indicates the last word with suffix s
  static const sCharacter = ' ';
  // Character that inserts the last word in the lookup array
  static const insertCharacter = '!';

  String tableIndex(index) {
    if (index < quickLookupSize) {
      // One character index
      return lookupCharacters[index];
    } else {
      // Two character index
      var index2 = index - quickLookupSize;
      var chIndex1 = index2 ~/ lookupCharacters2.length;
      var chIndex2 = index2 - chIndex1 * lookupCharacters2.length;
      return lookupCharacters[quickLookupSize + chIndex1] +
          lookupCharacters2[chIndex2];
    }
  }

  Buffer(this.lookupCharacters, this.lookupCharacters2, this.quickLookupSize,
      this.wordCharacters, this.prefixCharacters, this.specialCharacters)
      : buffer = StringBuffer();

  void writeEntry(String entry) {
    buffer.write(entry);
  }

  void writePluralEntry() {
    buffer.write(sCharacter);
  }

  void writeInsertEntry(int index) {
    buffer.write('$insertCharacter');
    writeIndexEntry(index);
  }

  void writeIndexEntry(int index) {
    buffer.write('${tableIndex(index)}');
  }

  String getEntry(int prefixLen, String suffix) {
    return '${prefixCharacters[prefixLen]}$suffix';
  }

  var bufferString = '';
  var bufferIndex = 0;
  String lastEntry = '';
  //TODO int quickLookupSize;
  List<String> readTable;
  String compressedBuffer = '';

  void _initBuffer() {
    if (bufferString == '') {
      bufferString = buffer.toString();
      var quickString = '';
      quickString += bufferString[bufferIndex++];
      quickString += bufferString[bufferIndex++];
      // Read quickLookupSize
      var readQuickLookupSize = int.parse(quickString);
      assert(
          readQuickLookupSize == quickLookupSize, 'Quick lookup size read ok');
      // Initialize lookup table
      var tableSize = quickLookupSize >= lookupCharacters.length
          ? quickLookupSize
          : quickLookupSize +
              (lookupCharacters.length - quickLookupSize) *
                  lookupCharacters2.length;
      readTable = List<String>(tableSize);
    }
  }

  String getBuffer() {
    _initBuffer();
    return bufferString;
  }

  String getCompressedBuffer(String buffer) {
    var stringBytes = utf8.encode(buffer);
    var gzipBytes = GZipEncoder().encode(stringBytes);
    var compressedBuffer = base64.encode(gzipBytes);
    return compressedBuffer;
  }

  String readEntry() {
    _initBuffer();
    if (bufferIndex >= bufferString.length) return '';

    var entry = bufferString[bufferIndex++];
    if (entry == sCharacter) {
      entry = lastEntry + 's';
    } else {
      var prefixLength = prefixCharacters.indexOf(entry);
      if (prefixLength >= 0) {
        while (bufferIndex < bufferString.length) {
          var char = bufferString[bufferIndex++];
          if (!wordCharacters.contains(char)) {
            bufferIndex--;
            break;
          }
          entry += char;
        }
        // Check for table insertion
        if (bufferIndex < bufferString.length &&
            bufferString[bufferIndex] == insertCharacter) {
          bufferIndex++;
          assert(bufferIndex < bufferString.length);
          var index = readIndex();
          readTable[index] = entry;
        }
      } else {
        bufferIndex--;
        var index = readIndex();
        assert(index < readTable.length, 'Index is within table');
        entry = readTable[index];
        prefixLength = prefixCharacters.indexOf(entry[0]);
      }
      var prefix = lastEntry.substring(0, prefixLength);
      entry = prefix + entry.substring(1);
    }
    lastEntry = entry;
    return entry;
  }

  int readIndex() {
    assert(bufferIndex < bufferString.length);
    var char = bufferString[bufferIndex++];
    var index = lookupCharacters.indexOf(char);
    assert(index >= 0);
    if (index >= quickLookupSize) {
      assert(bufferIndex < bufferString.length);
      char = bufferString[bufferIndex++];
      index = quickLookupSize +
          (index - quickLookupSize) * lookupCharacters2.length +
          lookupCharacters2.indexOf(char);
    }
    return index;
  }
}
