// @author luwenjie on 2026/01/17 14:37:53

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/dataforge.dart';

const String _generatedFileHeader =
    '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
    '// ignore_for_file: prefer_const_constructors, prefer_single_quotes, '
    'unnecessary_cast, unnecessary_non_null_assertion, unused_element';

/// Builder factory for build_runner integration
Builder dataforgeBuilder(BuilderOptions options) {
  return PartBuilder(
    [DataforgeGenerator()],
    '.data.dart',
    header: _generatedFileHeader,
  );
}
