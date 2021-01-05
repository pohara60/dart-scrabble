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
