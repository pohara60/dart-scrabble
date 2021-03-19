import 'dart:convert';
import 'dart:io';

import 'package:scrabble/scrabble.dart';
import 'package:test/test.dart';

void main() {
  group('API', () {
    final scrabble = Scrabble();
    test('lookup abba = {abba}', () {
      expect(scrabble.lookup('abba'), {'abba'});
    });
    test('lookup abc = {}', () {
      expect(scrabble.lookup('abc'), <String>{});
    });
    test('lookup expand ab? = {aba, abb, abo, abs, aby}', () {
      expect(scrabble.lookup('ab?', expand: true),
          <String>{'aba', 'abb', 'abo', 'abs', 'aby'});
    });
    test('anagram zulu = {zulu, luz, ulu}', () {
      expect(scrabble.anagram('zulu'), {'zulu', 'luz', 'ulu'});
    });
    test('anagram sort zulu = {luz, ulu, zulu}', () {
      expect(scrabble.anagram('zulu'), {'luz', 'ulu', 'zulu'});
    });
    test('anagram ?bt', () {
      expect(scrabble.anagram('?bt'), {'?b', '?t', 'b?', 'b?t', 't?', 't?b'});
    });
    test('anagram minLength 3 ?bt', () {
      expect(scrabble.anagram('?bt', minLength: 3), {'b?t', 't?b'});
    });
    test('anagram expand ?bt', () {
      expect(scrabble.anagram('?bt', expand: true), {
        'ab',
        'ob',
        'at',
        'et',
        'it',
        'st',
        'ut',
        'ba',
        'be',
        'bi',
        'bo',
        'by',
        'bat',
        'bet',
        'bit',
        'bot',
        'but',
        'ta',
        'te',
        'ti',
        'to',
        'tab',
        'tub'
      });
    });
    test('anagram expand minLength 3 ?bt', () {
      expect(scrabble.anagram('?bt', expand: true, minLength: 3),
          {'bat', 'bet', 'bit', 'bot', 'but', 'tab', 'tub'});
    });
    test('anagram zz = {}', () {
      expect(scrabble.anagram('zz'), <Set>{});
    });
    test('score zulu = 13', () {
      expect(scrabble.score('zulu'), 13);
    });
  });

  group('Command line', () {
    test_command('lookup abba', ['Lookup abba {abba}', 'Score abba = 8']);
    test_command('anagram --expand --minLength 3 ?bt', [
      'Anagram ?bt {bat, bet, bit, bot, but, tab, tub}',
      'Score bat = 5',
      'Score bet = 5',
      'Score bit = 5',
      'Score bot = 5',
      'Score but = 5',
      'Score tab = 5',
      'Score tub = 5',
    ]);
    test_command('anagram --expand --minLength 3 --sort tb?', [
      'Anagram tb? {bat, bet, bit, bot, but, tab, tub}',
      'Score bat = 5',
      'Score bet = 5',
      'Score bit = 5',
      'Score bot = 5',
      'Score but = 5',
      'Score tab = 5',
      'Score tub = 5',
    ]);
  });
}

// Test the command line program
// command is the scrabble command, e.g. 'lookup abba'
// output is the list of expected output lines
void test_command(String command, List<String> output) {
  final path = 'bin/scrabble.dart';
  test(command, () async {
    final process =
        await Process.start('dart', ['$path', ...command.split(' ')]);
    final lineStream =
        process.stdout.transform(Utf8Decoder()).transform(LineSplitter());

    // Test output is expected
    expect(
      lineStream,
      emitsInOrder([
        // Lines of output
        ...output,
        // Assert that the stream emits a done event and nothing else
        emitsDone
      ]),
    );

    // Pipe the error output and exit code (if any)
    await process.stderr.pipe(stderr);
    var code = await process.exitCode;
    if (code != 0) {
      print('exit code: $code');
    }
  });
}
