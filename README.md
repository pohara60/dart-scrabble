# Scrabble Library for Dart

## Introduction

**Scrabble** provides an API and command line tool for finding and scoring 
legal Scrabble words defined in the SOWPODS dictionary (see 
https://en.wikipedia.org/wiki/Collins_Scrabble_Words).

* The API includes methods to:
  * **lookup** legal words, perhaps includng the wildcard '?'.
  * get all legal **anagram**s of a string, perhaps including the wildcard '?'.
  * get the **score** for a word.
* The command line tool provides access to the API from the command line.

## Installing Scrabble

1. Depend on it

   Add this to your package's pubspec.yaml file:
   ```
   dependencies:
     scrabble: ^0.1.0
   ```

2. Install it

   You can install packages from the command line:
   ```bash
   $ dart pub get
   ```

3. Import it

   Now in your Dart code, you can use:
   ```dart
   import 'package:scrabble/scrabble.dart';
   ```

4. Install Command Line tool

   Activate the command:
   ```bash
   $ dart pub global activate scrabble
   ```

   If this doesn’t work, you might need to [set up your path](https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path).

## Examples

### Dart Example

See `example/example.dart`

```dart
import 'package:scrabble/scrabble.dart';

void main(List<String> args) {
  final scrabble = Scrabble();
  // Lookup arguments
  for (var word in args) {
    var matches = scrabble.lookup(word, expand: true);
    printMatches(scrabble, 'Lookup', word, matches);
  }
  // Get anagrams of arguments
  for (var word in args) {
    var matches = scrabble.anagram(word, expand: true, sort: true);
    printMatches(scrabble, 'Anagram', word, matches);
  }
}

// Print matches with scores
void printMatches(
    Scrabble scrabble, String command, String word, Set<String> matches) {
  print('$command $word $matches');
  for (var match in matches) {
    print('Score $match = ${scrabble.score(match)}');
  }
}
```

### Command Line Example

The command line tool has many options as described in the help text, run:
```bash
$ dart run scrabble --help
...
```

This example does a lookup for three letter words including 'a', 'b' and the wildcard '?'.

```bash
$ dart run scrabble lookup --expand ab?
Lookup ab? {aba, abb, abo, abs, aby}
Score aba = 5
Score abb = 7
Score abo = 5
Score abs = 5
Score aby = 8
```

### Web Example

See `example/web/web.dart`.

This is a version of the Scrabble example at https://dart.dev/tutorials/web/low-level-html/add-elements#moving-elements, 
modified to use the Scrabble package.


## Package Development

This documentation is not needed to use the package, just for its development.

The package converts the cleartext dictionary file (lib/sowpods.txt) into a 
compressed string buffer at package development time, using the Dart 
**builder_runner** package and the command:
```bash
dart run build_runner build
```
This approach was adopted to provide web client-side access to the dictionary.
