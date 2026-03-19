import 'dart:async';
import 'dart:io';

import 'package:dataforge_cli/src/parser.dart';
import 'package:test/test.dart';

void main() {
  group('Parser', () {
    test('parseDartFile does not write debug output for valid files', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('dataforge_parser_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = File('${tempDir.path}/user.dart');
      await file.writeAsString('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class User {
  final String name;
  final int age;

  const User({
    required this.name,
    required this.age,
  });
}
''');

      final output = <String>[];
      final result = await runZoned(
        () async => Parser(file.path).parseDartFile(),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, String line) {
            output.add(line);
          },
        ),
      );

      expect(result, isNotNull);
      expect(result!.classes, hasLength(1));
      expect(result.classes.single.fields, hasLength(2));
      expect(result.classes.single.fields[0].isRequired, isTrue);
      expect(result.classes.single.fields[1].isRequired, isTrue);
      expect(output, isEmpty);
    });

    test('marks positional constructor parameters as required', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('dataforge_parser_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = File('${tempDir.path}/user.dart');
      await file.writeAsString('''
import 'package:dataforge_annotation/dataforge_annotation.dart';

@Dataforge()
class User {
  final String name;
  final int age;

  const User(this.name, this.age);
}
''');

      final result = Parser(file.path).parseDartFile();

      expect(result, isNotNull);
      expect(result!.classes, hasLength(1));
      expect(result.classes.single.fields, hasLength(2));
      expect(result.classes.single.fields[0].isRequired, isTrue);
      expect(result.classes.single.fields[1].isRequired, isTrue);
    });
  });
}
