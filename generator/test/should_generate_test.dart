import 'dart:async';
import 'package:dataforge/src/dataforge.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen_test/source_gen_test.dart';

Future<void> main() async {
  initializeBuildLogTracking();

  // Test files organized by category
  final testFiles = [
    'basic_types_examples.dart',
    'nullable_examples.dart',
    'json_key_examples.dart',
    'converter_examples.dart',
    'collection_examples.dart',
    'nested_examples.dart',
    'generic_examples.dart',
    'enum_examples.dart',
    'datetime_examples.dart',
    'dataforge_options_examples.dart',
  ];

  for (final file in testFiles) {
    final reader = await initializeLibraryReaderForDirectory(
      p.join('test', 'src', 'examples'),
      file,
    );
    testAnnotatedElements(
      reader,
      DataforgeGenerator(),
    );
  }
}
