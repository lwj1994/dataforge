import 'dart:async';
import 'package:dataforge_generator/src/dataforge_generator.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen_test/source_gen_test.dart';

Future<void> main() async {
  initializeBuildLogTracking();
  final reader = await initializeLibraryReaderForDirectory(
    p.join('test', 'src'),
    'generator_examples.dart',
  );

  testAnnotatedElements(
    reader,
    DataforgeGenerator(),
  );
}
