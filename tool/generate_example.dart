#!/usr/bin/env dart

import 'package:dataforge/dataforge.dart';

void main(List<String> args) {
  final directory = args.isNotEmpty ? args[0] : 'example';
  print('Generating code for directory: $directory');
  generate(directory);
  print('Code generation completed.');
}
