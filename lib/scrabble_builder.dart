import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:scrabble/buffer.dart';

class ScrabbleBuilder {
  // Compress Scrabble word file into a compressed readable string
  //
  // The steps in the compression are as follows:
  // 1. Prefix encoding
  //    The current word is compared with the previous word
  //    The word is encoded as the length of the common prefix followed by the suffix
  //    For example: use, used, useful, usefully are encoded as 0use, 3d, 3ful, 6ly
  // 2. Plural optimization
  //    Words that are the previous word with suffix 's' are represented by a special flag character
  // 3. Dictionary encoding - optional, minimal effect
  //    Every word (with its prefix length) is added to a dictionary with the count of occurrences
  //    The dictionary is sorted by occurrence count, and the most valuable are usied in a lookup array
  // 4. GZIP and Base64 of compressed buffer
  //

  // Word characters
  static const wordCharacters = 'abcdefghijklmnopqrstuvwxyz';
  // Characters that specify prefix length (0 to 15)
  static const prefixCharacters = '0123456789ABCDEF';
  // Other special characters that can appear in a string represented as one character
  // Omit \, " and ' for Javascript and $ for Dart
  static const specialCharacters = '#%&()*+,-./:;<=>?@[]^_`{|}~';
  // Characters that are used as indexes into the lookup array
  // Some number (default 20) are used as a one character index
  // Others are used as first character of a two character index
  static const lookupCharacters = 'GHIJKLMNOPQRSTUVWXYZ' + specialCharacters;
  // Characters that are used as second character of a two character index
  static const lookupCharacters2 =
      wordCharacters + prefixCharacters + lookupCharacters;

  void compressScrabble(String dictionary,
      {bool statistics = false,
      bool verbose = false,
      bool useLookup = false,
      int quickSize = -1}) {
    // Lookup dimensions
    final quickLookupSize = quickSize < 0 || quickSize > lookupCharacters.length
        ? lookupCharacters.length
        : quickSize;
    final lookupSize = quickLookupSize >= lookupCharacters.length
        ? quickLookupSize
        : quickLookupSize +
            (lookupCharacters.length - quickLookupSize) *
                lookupCharacters2.length;

    // Buffer for compressed dictionary
    var buffer = Buffer(lookupCharacters, lookupCharacters2, quickLookupSize,
        wordCharacters, prefixCharacters, specialCharacters);

    // First pass computes lookup table, second pass uses it, third pass validates
    var lookupTable = <String, int>{};

    for (var pass = 1; pass <= 3; pass++) {
      if (pass == 2 && !useLookup) {
        // No need for second pass if no lookup table
        continue;
      }
      final stopwatch = Stopwatch()..start();

      var lines = LineSplitter().convert(dictionary);

      var last = '';
      var size = 0;
      var compressed = 0;
      var entries = <String, int>{};

      // Write buffer on pass 1 if not useLookup, else pass2
      var writing = !useLookup && pass == 1 || useLookup && pass == 2;

      // Write quickLookupSize so decoder knows it
      if (writing) {
        buffer.writeEntry(quickLookupSize.toString().padLeft(2, '0'));
      }

      for (var line in lines) {
        if (pass < 3) {
          // Compute length of common prefix with last word
          int prefixLen;
          for (prefixLen = 0;
              prefixLen < line.length &&
                  prefixLen < last.length &&
                  last[prefixLen] == line[prefixLen];
              // ignore: curly_braces_in_flow_control_structures
              prefixLen++);
          // Limit on prefix length
          if (prefixLen >= prefixCharacters.length) {
            prefixLen = prefixCharacters.length - 1;
          }
          var length = 1 + line.length - prefixLen;

          if (prefixLen == last.length &&
              prefixLen == line.length - 1 &&
              line[line.length - 1] == 's') {
            // Optimize plurals
            length = 1;
            if (writing) {
              buffer.writePluralEntry();
            }
          } else {
            var suffix = line.substring(prefixLen);
            var entry = buffer.getEntry(prefixLen, suffix);
            if (useLookup && pass == 1) {
              if (entries.containsKey(entry)) {
                entries[entry] += 1;
              } else {
                entries[entry] = 0;
              }
            } else {
              if (useLookup && lookupTable.containsKey(entry)) {
                var index = lookupTable[entry];
                if (index >= 0) {
                  // First reference so write entry followed by table insert
                  buffer.writeEntry(entry);
                  buffer.writeInsertEntry(index);
                  lookupTable[entry] = -index;
                } else {
                  // Subsequent reference so write table index
                  buffer.writeIndexEntry(-index);
                }
              } else {
                buffer.writeEntry(entry);
              }
            }
          }
          if (pass == 1) {
            size += line.length;
            compressed += length;
          }

          // Save last line for prefix computation
          last = line;
        } else {
          // Pass 3 validation
          var entry = buffer.readEntry();
          assert(entry == line, 'Buffer entry matches line');
        }
      }

      // Post-processing
      if (pass == 1) {
        var saving = 0;
        if (useLookup) {
          var sortedKeys = entries.keys.toList(growable: false)
            ..sort((k1, k2) =>
                -lookupValue(entries, k1).compareTo(lookupValue(entries, k2)));
          var index = 0;
          for (var key in sortedKeys) {
            // Is it worth adding entry to lookup table?
            var count = entries[key];
            var value = lookupValue(entries, key);
            var lookupIndex = (index < quickLookupSize ? 1 : 2);
            var cost = lookupIndex * entries[key] + lookupIndex + 1;
            if (cost >= value) continue;

            // Add entry to lookup table
            lookupTable[key] = index;
            saving += value - cost;
            if (statistics && verbose) {
              stdout.writeln(
                  '$index: suffix $key = $count, value = $value, cost = $cost, saving = $saving');
            }

            // Break if lookup table is full
            if (++index >= lookupSize) break;
          }
        }
        if (statistics) {
          stdout.writeln(
              'Dictionary size $size prefix compression $compressed lookup saving $saving');
          if (writing) {
            var length = buffer.getBuffer().length;
            stdout.writeln('Buffer size $length');
            stdout.writeln('Pass 1: buffer written in ${stopwatch.elapsed}');
          } else {
            stdout.writeln('Pass 1: dictionary loaded in ${stopwatch.elapsed}');
          }
        }
      } else if (pass == 2) {
        if (statistics) {
          var length = buffer.getBuffer().length;
          stdout.writeln('Compressed buffer size $length');
          stdout.writeln('Pass 2: buffer written in ${stopwatch.elapsed}');
        }
      } else if (pass == 3) {
        if (statistics) {
          stdout.writeln('Pass 3: buffer validated in ${stopwatch.elapsed}');
        }
        stopwatch.start();
        var compressedBuffer = buffer.getCompressedBuffer(buffer.getBuffer());
        if (statistics) {
          var length = compressedBuffer.length;
          stdout.writeln('GZIP buffer size $length');
          stdout.writeln('Pass 3: buffer compressed in ${stopwatch.elapsed}');
        }
      }
    }
  }

  int lookupValue(Map<String, int> map, String key) {
    return key.length * map[key];
  }
}
