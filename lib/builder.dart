import 'package:build/build.dart';
import 'package:scrabble/scrabble_builder.dart';

Builder compressBuilder(BuilderOptions options) => CompressBuilder();

/// Compresses contents of a `txt` files into `name.dart`.
///
/// A header row is added pointing to the input file name.
class CompressBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    var inputId = buildStep.inputId;
    var dictionary = await buildStep.readAsString(inputId);

    var builder = ScrabbleBuilder();
    var buffer = builder.compressScrabble(dictionary);

    var copy = inputId.changeExtension('.dart');

    // Write out the new asset.
    await buildStep.writeAsString(
        copy, '// Compressed from $inputId\n\nvar buffer = \'$buffer\';\n');
  }

  @override
  final buildExtensions = const {
    '.txt': ['.dart']
  };
}
