import 'dart:io';

import 'package:args/args.dart';
import 'package:dataforge_cli/dataforge_cli.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty &&
      (arguments.first == '--help' || arguments.first == '-h')) {
    _printHelp();
    return;
  }
  if (arguments.isEmpty) {
    exitCode = 2;
    stderr.writeln('❌ Missing command. Expected generate or check.');
    return;
  }
  final command = arguments.first;
  if (command != 'generate' && command != 'check') {
    exitCode = 2;
    stderr.writeln('❌ Unknown command: $command. Expected generate or check.');
    return;
  }
  final commandArguments = arguments.skip(1).toList();

  final parser = ArgParser()
    ..addOption('path', defaultsTo: '')
    ..addFlag(
      'debug',
      abbr: 'd',
      defaultsTo: false,
      negatable: false,
      help: 'Enable debug logging',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      defaultsTo: false,
      negatable: false,
      help: 'Show help information',
    );

  late final ArgResults result;
  try {
    result = parser.parse(commandArguments);
  } on FormatException catch (error) {
    exitCode = 2;
    stderr.writeln('❌ Invalid arguments: $error');
    return;
  }

  if (result.flag('help')) {
    _printHelp();
    return;
  }

  final optionPath = result.option('path') ?? '';
  if (result.rest.length > 1 ||
      (optionPath.isNotEmpty && result.rest.isNotEmpty)) {
    exitCode = 2;
    stderr.writeln('❌ Invalid arguments: expected exactly zero or one path.');
    return;
  }
  final path = optionPath.isNotEmpty
      ? optionPath
      : result.rest.isNotEmpty
      ? result.rest.single
      : Directory.current.path;
  final check = command == 'check';
  final debugMode = result.flag('debug');

  if (debugMode) {
    print(
      '[DEBUG] ${DateTime.now()}: command=$command path=$path check=$check',
    );
  }
  print(check ? '🔎 Checking generated code' : '🔨 Generating code');

  try {
    final generatedFiles = await generate(
      path,
      debugMode: debugMode,
      check: check,
    );
    if (check) {
      print('\n✅ Generated output is up to date.');
    } else if (generatedFiles.isEmpty) {
      print('\n✅ No generated output required.');
    } else {
      print('\n✅ Generated ${generatedFiles.length} file(s).');
    }
  } on DataforgeCliException catch (error, stackTrace) {
    exitCode = error.exitCode;
    stderr.writeln('\n❌ Generation failed: $error');
    if (debugMode) stderr.writeln(stackTrace);
  } on FileSystemException catch (error, stackTrace) {
    exitCode = 5;
    stderr.writeln('\n❌ Generation I/O failed: $error');
    if (debugMode) stderr.writeln(stackTrace);
  } catch (error, stackTrace) {
    exitCode = 70;
    stderr.writeln('\n❌ Internal Dataforge error: $error');
    if (debugMode) stderr.writeln(stackTrace);
  }
}

void _printHelp() {
  print('Dataforge - v1 immutable value-object generator\n');
  print('Usage: dataforge generate [path] [options]');
  print('       dataforge check [path] [options]\n');
  print('Arguments:');
  print(
    '  path              Dart source or directory (default: current directory)',
  );
  print('Options:');
  print('  -d, --debug       Enable debug logging');
  print('  -h, --help        Show this help information');
}
