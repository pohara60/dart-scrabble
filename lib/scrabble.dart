library scrabble;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:scrabble/buffer.dart';
import 'package:scrabble/scrabble_builder.dart';

part 'sowpods.dart';

class Scrabble {
  static const dictionaryFile = 'lib/sowpods.txt';
  static final dictionary = <String>{};

  static const List<String> alphabet = [
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
    initScrabble();
  }

  void initScrabble() {
    if (dictionary.isNotEmpty) return;

    var readBuffer = Buffer(lookupCharacters, lookupCharacters2, null,
        wordCharacters, prefixCharacters, specialCharacters);
    readBuffer.setCompressedBuffer(buffer);
    String entry;
    while ((entry = readBuffer.readEntry()) != '') {
      dictionary.add(entry);
    }
    // //final stopwatch = Stopwatch()..start();
    // final lines = utf8.decoder
    //     .bind(File(dictionaryFile).openRead())
    //     .transform(const LineSplitter());

    // await for (var line in lines) {
    //   dictionary.add(line);
    // }
    // // print('dictionary loaded in ${stopwatch.elapsed}');
  }

  void compressScrabble(
      {bool statistics = false,
      bool verbose = false,
      bool useLookup = false,
      int quickSize = -1}) {
    var builder = ScrabbleBuilder();
    builder.compressScrabble(File(dictionaryFile).readAsStringSync(),
        statistics: statistics,
        verbose: verbose,
        useLookup: useLookup,
        quickSize: quickSize);
  }

  Set<String> lookup(String word, {bool expand = false}) {
    var matches = dictionaryLookup('', word);
    if (matches.isNotEmpty) {
      if (!expand) {
        return {word};
      } else {
        return matches;
      }
    }
    return {};
  }

  Set<String> anagram(String word,
      {bool expand = false, bool sort = false, int minLength = 2}) {
    var anagrams = <String>{};
    anagramWord(anagrams, '', word, expand, minLength);
    if (sort) {
      return SplayTreeSet.from(anagrams);
    }
    return anagrams;
  }

  void anagramWord(Set<String> anagrams, String start, String rest, bool expand,
      int minLength) {
    // print('anagramWord: start=$start, rest=$rest');
    if (start.length >= minLength) {
      // Include partial anagrams
      var matches = dictionaryLookup('', start);
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
        anagramWord(anagrams, start + rest[i],
            rest.substring(0, i) + rest.substring(i + 1), expand, minLength);
      }
    }
  }

  Set<String> dictionaryLookup(String start, String rest) {
    // print('start=$start');
    // print('rest=$rest');
    var index = rest.indexOf('?');
    // print('index=$index');
    if (index == -1) {
      var word = start + rest;
      if (dictionary.contains(word)) {
        // print('dictionaryLookup: dictionary contains $word');
        return {word};
      }
      return {};
    }

    var prefix = rest.substring(0, index);
    // print('prefix=$prefix');
    // Wildcard
    var matches = <String>{};
    for (var c in alphabet) {
      matches.addAll(dictionaryLookup(prefix + c, rest.substring(index + 1)));
    }
    return matches;
  }

  int score(String word) {
    var total = 0;
    for (var i = 0; i < word.length; i++) {
      total += scrabbleValues[word[i]];
    }
    return total;
  }
}
