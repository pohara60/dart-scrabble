import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:scrabble/scrabble.dart';

const help = 'help';
const program = 'scrabble';

void main(List<String> arguments) {
  exitCode = 0; // presume success

  var runner = CommandRunner('scrabble', 'Scrabble helper.')
    ..addCommand(LookupCommand())
    // ..addCommand(CompressCommand())
    ..addCommand(AnagramCommand());
  try {
    runner.run(arguments);
  } on UsageException catch (e) {
    // Arguments exception
    print('$program: ${e.message}');
    print('');
    print('${runner.usage}');
  }
}

class LookupCommand extends Command {
  @override
  final name = 'lookup';
  @override
  final description = 'Lookup <arguments> in dictionary.';

  LookupCommand() {
    argParser.addFlag(
      'expand',
      abbr: 'e',
      negatable: false,
      help: 'Output expanded wildcards.',
    );
  }

  @override
  void run() {
    // Get and print lookup
    final scrabble = Scrabble();
    for (var word in argResults.rest) {
      var matches = scrabble.lookup(word, expand: argResults['expand']);
      printMatches(scrabble, 'Lookup', word, matches);
    }
  }
}

class AnagramCommand extends Command {
  @override
  final name = 'anagram';
  @override
  final description =
      'Form partial anagrams of <arguments> that appear in the dictionary.';

  AnagramCommand() {
    argParser.addFlag(
      'expand',
      abbr: 'e',
      negatable: false,
      help: 'Output expanded wildcards.',
    );
    argParser.addFlag(
      'sort',
      abbr: 's',
      negatable: false,
      help: 'Sort results.',
    );
    argParser.addOption(
      'minLength',
      abbr: 'm',
      help: 'Minimum length of matching words, defaults to 2.',
      valueHelp: 'Integer length',
    );
  }

  @override
  void run() {
    // Validate options
    var minLength = argResults['minLength'];
    if (minLength != null) {
      if (int.tryParse(minLength) == null || int.parse(minLength) < 1) {
        print('--minLength value must be a positive integer.');
        exit(64);
      }
    } else {
      minLength = '2';
    }
    // Get and print anagrams
    final scrabble = Scrabble();
    for (var word in argResults.rest) {
      var anagrams = scrabble.anagram(word,
          expand: argResults['expand'],
          sort: argResults['sort'],
          minLength: int.parse(minLength));
      printMatches(scrabble, 'Anagram', word, anagrams);
    }
  }
}

void printMatches(
    Scrabble scrabble, String command, String word, Set<String> matches) {
  print('$command $word $matches');
  for (var match in matches) {
    print('Score $match = ${scrabble.score(match)}');
  }
}

// class CompressCommand extends Command {
//   @override
//   final name = 'compress';
//   @override
//   final description = 'Compress dictionary.';

//   CompressCommand() {
//     argParser.addFlag(
//       'statistics',
//       abbr: 's',
//       negatable: false,
//       help: 'Output statistics instead of compressed dictionary.',
//     );
//     argParser.addFlag(
//       'useLookup',
//       abbr: 'u',
//       negatable: false,
//       help: 'Use dictionary encoding, minimal improvement.',
//     );
//     argParser.addFlag(
//       'verbose',
//       abbr: 'v',
//       negatable: false,
//       help: 'Output verbose statistics.',
//     );
//     argParser.addOption(
//       'quickSize',
//       abbr: 'q',
//       help: 'Quick lookup size, defaults to maximum possible.',
//       valueHelp: 'Integer length',
//     );
//   }

//   @override
//   void run() {
//     // Validate options
//     var quick = argResults['quickSize'];
//     if (quick != null) {
//       if (int.tryParse(quick) == null || int.parse(quick) < 1) {
//         print('--quickSize value must be a positive integer.');
//         exit(64);
//       }
//     } else {
//       quick = '-1';
//     }
//     // Get and print Compress
//     final scrabble = Scrabble();
//     scrabble.compressScrabble(
//       statistics: argResults['statistics'],
//       useLookup: argResults['useLookup'],
//       verbose: argResults['verbose'],
//       quickSize: int.parse(quick),
//     );
//   }
// }
