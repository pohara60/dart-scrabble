// Modified version of example at:
// https://dart.dev/tutorials/web/low-level-html/add-elements#moving-elements
// Copyright (c) 2012, the Dart project authors.  Please see the
// AUTHORS file for details. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:math';

import 'package:scrabble/scrabble.dart';

// Should remove tiles from here when they are selected otherwise
// the ratio is off.

List<ButtonElement> buttons = [];
Element letterpile;
Element result;
ButtonElement clearButton;
Element lettersValue;
int wordvalue = 0;

Scrabble scrabble;
Element scrabbleValue;
ButtonElement anagramButton;
Element anagramList;

void main() {
  scrabble = Scrabble();
  letterpile = querySelector('#letterpile');
  result = querySelector('#result');
  lettersValue = querySelector('#lettersValue');
  scrabbleValue = querySelector('#scrabbleValue');

  clearButton = querySelector('#clearButton');
  clearButton.onClick.listen(newletters);

  anagramButton = querySelector('#anagramButton');
  anagramButton.onClick.listen(getAnagrams);
  anagramList = querySelector('#anagrams');

  generateNewLetters();
}

void moveLetter(Event e) {
  Element letter = e.target;
  if (letter.parent == letterpile) {
    result.children.add(letter);
    wordvalue += Scrabble.scrabbleValues[letter.text];
    lettersValue.text = '$wordvalue';
  } else {
    letterpile.children.add(letter);
    wordvalue -= Scrabble.scrabbleValues[letter.text];
    lettersValue.text = '$wordvalue';
  }

  // Get Word, show score if it is legal
  var word = getWord(result);
  if (scrabble.lookup(word).isNotEmpty) {
    scrabbleValue.text = scrabble.score(word).toString();
  } else {
    scrabbleValue.text = '';
  }
}

void newletters(Event e) {
  letterpile.children.clear();
  result.children.clear();
  anagramList.children.clear();
  generateNewLetters();
}

void generateNewLetters() {
  var indexGenerator = Random();
  wordvalue = 0;
  lettersValue.text = '';
  scrabbleValue.text = '';
  buttons.clear();
  for (var i = 0; i < 7; i++) {
    var letterIndex = indexGenerator.nextInt(Scrabble.scrabbleLetters.length);
    // Should remove the letter from scrabbleLetters to keep the
    // ratio correct.
    buttons.add(ButtonElement());
    buttons[i].classes.add('letter');
    buttons[i].onClick.listen(moveLetter);
    buttons[i].text = Scrabble.scrabbleLetters[letterIndex];
    letterpile.children.add(buttons[i]);
  }
}

void getAnagrams(Event e) {
  var word = getWord(letterpile);
  var anagrams = scrabble.anagram(word, expand: true);
  anagramList.children.clear();
  for (var anagram in anagrams) {
    var link = AnchorElement();
    link.text = anagram + ' (' + scrabble.score(anagram).toString() + ')';
    link.href =
        'https://www.collinsdictionary.com/dictionary/english/' + anagram;
    link.target = '_blank';
    link.classes.add('anagram');
    anagramList.children.add(link);
    anagramList.children.add(BRElement());
  }
}

String getWord(Element result) {
  var word = '';
  for (var letter in result.children) {
    word += letter.text;
  }
  return word;
}
