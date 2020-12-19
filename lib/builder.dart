import 'package:build/build.dart';

Builder compressBuilder(BuilderOptions options) => CompressBuilder();

/// Compresses contents of a `txt` files into `name.dart`.
///
/// A header row is added pointing to the input file name.
class CompressBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    // Each [buildStep] has a single input.
    var inputId = buildStep.inputId;

    // Create a new target [AssetId] based on the old one.
    //var contents = await buildStep.readAsString(inputId);

    var copy = inputId.changeExtension('.dart');

    // Write out the new asset.
    await buildStep.writeAsString(copy, '// Compressed from $inputId\n');
  }

  @override
  final buildExtensions = const {
    '.txt': ['.dart']
  };
}
