import 'dart:convert';

import 'package:archive/archive.dart';

/// Access compressed dictionary string.
///
/// Read methods are used by the run-time [Scrabble] API.
/// Write methods are used at development time by [ScrabbleBuilder].
class Buffer {
  final StringBuffer _buffer;
  final String _lookupCharacters;
  final String _lookupCharacters2;
  final _wordCharacters;
  final _prefixCharacters;
  // ignore: unused_field
  final _specialCharacters;
  int _quickLookupSize; // Not final because read on input

  // Character that indicates the last word with suffix s
  static const _sCharacter = ' ';
  // Character that inserts the last word in the lookup array
  static const _insertCharacter = '!';

  String _tableIndex(index) {
    if (index < _quickLookupSize) {
      // One character index
      return _lookupCharacters[index];
    } else {
      // Two character index
      var index2 = index - _quickLookupSize;
      var chIndex1 = index2 ~/ _lookupCharacters2.length;
      var chIndex2 = index2 - chIndex1 * _lookupCharacters2.length;
      return _lookupCharacters[_quickLookupSize + chIndex1] +
          _lookupCharacters2[chIndex2];
    }
  }

  Buffer(this._lookupCharacters, this._lookupCharacters2, this._quickLookupSize,
      this._wordCharacters, this._prefixCharacters, this._specialCharacters)
      : _buffer = StringBuffer();

  void writeEntry(String entry) {
    _buffer.write(entry);
  }

  void writePluralEntry() {
    _buffer.write(_sCharacter);
  }

  void writeInsertEntry(int index) {
    _buffer.write('$_insertCharacter');
    writeIndexEntry(index);
  }

  void writeIndexEntry(int index) {
    _buffer.write('${_tableIndex(index)}');
  }

  String getEntry(int prefixLen, String suffix) {
    return '${_prefixCharacters[prefixLen]}$suffix';
  }

  var _bufferString = '';
  var _bufferIndex = 0;
  String _lastEntry = '';
  List<String> _readTable;
  String _compressedBuffer = '';

  void _initBuffer() {
    if (_bufferString == '') {
      _bufferString = _buffer.toString();
      _initTable();
    }
  }

  void _initTable() {
    var quickString = '';
    quickString += _bufferString[_bufferIndex++];
    quickString += _bufferString[_bufferIndex++];
    // Read quickLookupSize
    _quickLookupSize = int.parse(quickString);
    // Initialize lookup table
    var tableSize = _quickLookupSize >= _lookupCharacters.length
        ? _quickLookupSize
        : _quickLookupSize +
            (_lookupCharacters.length - _quickLookupSize) *
                _lookupCharacters2.length;
    _readTable = List<String>(tableSize);
  }

  String getBuffer() {
    _initBuffer();
    return _bufferString;
  }

  void setCompressedBuffer(String buffer) {
    _compressedBuffer = buffer;
    var gzipBytes = base64.decode(_compressedBuffer);
    var stringBytes = GZipDecoder().decodeBytes(gzipBytes);
    _bufferString = utf8.decode(stringBytes);
    _initTable();
  }

  String getCompressedBuffer(String buffer) {
    if (_compressedBuffer == '') {
      var stringBytes = utf8.encode(buffer);
      var gzipBytes = GZipEncoder().encode(stringBytes);
      _compressedBuffer = base64.encode(gzipBytes);
    }
    return _compressedBuffer;
  }

  String readEntry() {
    _initBuffer();
    if (_bufferIndex >= _bufferString.length) return '';

    var entry = _bufferString[_bufferIndex++];
    if (entry == _sCharacter) {
      entry = _lastEntry + 's';
    } else {
      var prefixLength = _prefixCharacters.indexOf(entry);
      if (prefixLength >= 0) {
        while (_bufferIndex < _bufferString.length) {
          var char = _bufferString[_bufferIndex++];
          if (!_wordCharacters.contains(char)) {
            _bufferIndex--;
            break;
          }
          entry += char;
        }
        // Check for table insertion
        if (_bufferIndex < _bufferString.length &&
            _bufferString[_bufferIndex] == _insertCharacter) {
          _bufferIndex++;
          assert(_bufferIndex < _bufferString.length);
          var index = readIndex();
          _readTable[index] = entry;
        }
      } else {
        _bufferIndex--;
        var index = readIndex();
        assert(index < _readTable.length, 'Index is within table');
        entry = _readTable[index];
        prefixLength = _prefixCharacters.indexOf(entry[0]);
      }
      var prefix = _lastEntry.substring(0, prefixLength);
      entry = prefix + entry.substring(1);
    }
    _lastEntry = entry;
    return entry;
  }

  int readIndex() {
    assert(_bufferIndex < _bufferString.length);
    var char = _bufferString[_bufferIndex++];
    var index = _lookupCharacters.indexOf(char);
    assert(index >= 0);
    if (index >= _quickLookupSize) {
      assert(_bufferIndex < _bufferString.length);
      char = _bufferString[_bufferIndex++];
      index = _quickLookupSize +
          (index - _quickLookupSize) * _lookupCharacters2.length +
          _lookupCharacters2.indexOf(char);
    }
    return index;
  }
}
