// @author luwenjie on 2026/01/17 14:37:53

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/dataforge.dart';

/// Builder factory for build_runner integration
Builder dataforgeBuilder(BuilderOptions options) {
  return PartBuilder(
    [DataforgeGenerator()],
    '.data.dart',
  );
}
