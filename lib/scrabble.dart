/// An API for finding and scoring legal Scrabble words.
///
/// The legal words are defined in the SOWPODS dictionary (see
/// https://en.wikipedia.org/wiki/Collins_Scrabble_Words).
library scrabble;

import 'dart:collection';
import 'dart:io';

import './src/buffer.dart';
import './scrabble_builder.dart';

// Part file has compressed dictionary buffer
part 'sowpods.dart';

/// Provide access to the Scrabble API.
class Scrabble {
  static const _dictionaryFile = 'lib/sowpods.txt';
  static final _dictionary = <String>{};

  static const List<String> _alphabet = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z'
  ];

  static const String scrabbleLetters =
      'aaaaaaaaabbccddddeeeeeeeeeeeeffggghhiiiiiiiiijkllllmmnnnnnnooooooooppqrrrrrrssssttttttuuuuvvwwxyyz??';

  static const Map scrabbleValues = {
    'a': 1,
    'e': 1,
    'i': 1,
    'l': 1,
    'n': 1,
    'o': 1,
    'r': 1,
    's': 1,
    't': 1,
    'u': 1,
    'd': 2,
    'g': 2,
    'b': 3,
    'c': 3,
    'm': 3,
    'p': 3,
    'f': 4,
    'h': 4,
    'v': 4,
    'w': 4,
    'y': 4,
    'k': 5,
    'j': 8,
    'x': 8,
    'q': 10,
    'z': 10,
    '?': 0
  };

  Scrabble() {
    _initScrabble();
  }

  void _initScrabble() {
    if (_dictionary.isNotEmpty) return;

    //final stopwatch = Stopwatch()..start();
    // Read dictionary from buffer
    var readBuffer = Buffer(_lookupCharacters, _lookupCharacters2, null,
        _wordCharacters, _prefixCharacters, _specialCharacters);
    readBuffer.setCompressedBuffer(_buffer);
    String entry;
    while ((entry = readBuffer.readEntry()) != '') {
      _dictionary.add(entry);
    }
    // print('dictionary loaded in ${stopwatch.elapsed}');
  }

  /// **lookup** legal words, perhaps includng the wildcard '?'.
  ///
  /// If [expand] is true then wildcards are expanded.
  Set<String> lookup(String word, {bool expand = false}) {
    var matches = _dictionaryLookup('', word);
    if (matches.isNotEmpty) {
      if (!expand) {
        return {word};
      } else {
        return matches;
      }
    }
    return {};
  }

  /// Get all legal **anagram**s of a string, perhaps includng the wildcard '?'.
  ///
  /// If [expand] is true then wildcards are expanded.
  /// If [sort] is true then results are sorted into alphabetical order.
  /// If [minLength] is >2 then only matches of at least that length are returned.
  Set<String> anagram(String word,
      {bool expand = false, bool sort = false, int minLength = 2}) {
    var anagrams = <String>{};
    _anagramWord(anagrams, '', word, expand, minLength);
    if (sort) {
      return SplayTreeSet.from(anagrams);
    }
    return anagrams;
  }

  /// Get the **score** for a word.
  int score(String word) {
    var total = 0;
    for (var i = 0; i < word.length; i++) {
      total += scrabbleValues[word[i]];
    }
    return total;
  }

  /// Development-time utility to test compression strategies.
  void compressScrabble(
      {bool statistics = false,
      bool verbose = false,
      bool useLookup = false,
      int quickSize = -1,
      String fileName = _dictionaryFile}) {
    var builder = ScrabbleBuilder();
    builder.compressScrabble(File(fileName).readAsStringSync(),
        statistics: statistics,
        verbose: verbose,
        useLookup: useLookup,
        quickSize: quickSize);
  }

  void _anagramWord(Set<String> anagrams, String start, String rest,
      bool expand, int minLength) {
    // print('anagramWord: start=$start, rest=$rest');
    if (start.length >= minLength) {
      // Include partial anagrams
      var matches = _dictionaryLookup('', start);
      if (matches.isNotEmpty) {
        if (!expand) {
          anagrams.add(start);
        } else {
          anagrams.addAll(matches);
        }
      }
    }
    if (rest.isNotEmpty) {
      for (var i = 0; i < rest.length; i++) {
        _anagramWord(anagrams, start + rest[i],
            rest.substring(0, i) + rest.substring(i + 1), expand, minLength);
      }
    }
  }

  Set<String> _dictionaryLookup(String start, String rest) {
    // print('start=$start');
    // print('rest=$rest');
    var index = rest.indexOf('?');
    // print('index=$index');
    if (index == -1) {
      var word = start + rest;
      if (_dictionary.contains(word)) {
        // print('dictionaryLookup: dictionary contains $word');
        return {word};
      }
      return {};
    }

    var prefix = rest.substring(0, index);
    // print('prefix=$prefix');
    // Wildcard
    var matches = <String>{};
    for (var c in _alphabet) {
      matches.addAll(_dictionaryLookup(prefix + c, rest.substring(index + 1)));
    }
    return matches;
  }
}
