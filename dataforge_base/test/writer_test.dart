// Test for GeneratorWriter

import 'package:dataforge_base/dataforge_base.dart';
import 'package:test/test.dart';

void main() {
  group('GeneratorWriter', () {
    group('generate', () {
      test('generates mixin with basic fields', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
                FieldInfo(
                  name: 'age',
                  type: 'int',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('mixin _\$User'));
        expect(output, contains('abstract final String name;'));
        expect(output, contains('abstract final int age;'));
      });

      test('generates copyWith method for traditional style', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('User copyWith({'));
        expect(output, contains('String? name,'));
        expect(output, contains('name: (name ?? this.name),'));
      });

      test('generates chained copyWith for deepCopyWith style', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: true,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('UserCopyWith'));
        expect(output, contains('get copyWith => UserCopyWith'));
        expect(output, contains('class UserCopyWith'));
      });

      test('generates equality operator', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
                FieldInfo(
                  name: 'age',
                  type: 'int',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('bool operator ==(Object other)'));
        expect(output, contains('if (identical(this, other)) return true;'));
        expect(output, contains('if (other is! User) return false;'));
        expect(output, contains('other.name == name'));
        expect(output, contains('other.age == age'));
      });

      test('generates hashCode', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('int get hashCode => Object.hashAll'));
        expect(output, contains('name,'));
      });

      test('generates toString', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains("String toString() => 'User("));
        expect(output, contains('name: \$name'));
      });

      test('generates toJson when includeToJson is true', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              includeToJson: true,
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('Map<String, dynamic> toJson()'));
        expect(output, contains("'name': name,"));
      });

      test('does not generate toJson when includeToJson is false', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              includeToJson: false,
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, isNot(contains('Map<String, dynamic> toJson()')));
      });

      test('generates fromJson when includeFromJson is true', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              includeFromJson: true,
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output,
            contains('static User fromJson(Map<String, dynamic> json)'));
        expect(output, contains('return User('));
      });

      test('does not generate fromJson when includeFromJson is false', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              includeFromJson: false,
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, isNot(contains('static User fromJson')));
      });

      test('skips function fields', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
                FieldInfo(
                  name: 'callback',
                  type: 'void Function()',
                  isFinal: true,
                  isFunction: true,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('abstract final String name;'));
        expect(output, contains('abstract final void Function() callback;'));
        // Function field should not appear in copyWith parameters
        expect(output, isNot(contains('void Function()? callback,')));
      });

      test('skips dynamic fields in validFields', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
                FieldInfo(
                  name: 'data',
                  type: 'dynamic',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('abstract final String name;'));
        // Dynamic field should not be in abstract fields
        expect(output, isNot(contains('abstract final dynamic data;')));
      });

      test('handles nullable types', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'nickname',
                  type: 'String?',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('abstract final String? nickname;'));
        expect(output, contains('Object? nickname = dataforgeUndefined,'));
        expect(
          output,
          contains(
            "nickname: (nickname == dataforgeUndefined ? this.nickname : SafeCasteUtil.copyWithCastNullable<String>(nickname, 'nickname', this.nickname)),",
          ),
        );
      });

      test('omits null values from toJson when includeIfNull is false', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
                FieldInfo(
                  name: 'nickname',
                  type: 'String?',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  jsonKey: JsonKeyInfo(
                    name: '',
                    alternateNames: [],
                    readValue: '',
                    ignore: false,
                    converter: '',
                    includeIfNull: false,
                  ),
                ),
              ],
              includeToJson: true,
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains("'name': name,"));
        expect(output, contains("if (nickname != null) 'nickname': nickname,"));
      });

      test('handles generic parameters', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'Container',
              mixinName: '_\$Container',
              fields: [
                FieldInfo(
                  name: 'value',
                  type: 'T',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              genericParameters: [GenericParameter('T')],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('mixin _\$Container<T>'));
        expect(output, contains('Container<T> copyWith({'));
      });

      test('handles generic parameters with bounds', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'Container',
              mixinName: '_\$Container',
              fields: [
                FieldInfo(
                  name: 'value',
                  type: 'T',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              genericParameters: [GenericParameter('T', 'num')],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains('mixin _\$Container<T extends num>'));
      });

      test('handles List fields with DeepCollectionEquality', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'tags',
                  type: 'List<String>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output,
            contains('DeepCollectionEquality().equals(tags, other.tags)'));
        expect(output, contains('DeepCollectionEquality().hash(tags)'));
      });

      test('handles Map fields with DeepCollectionEquality', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'metadata',
                  type: 'Map<String, dynamic>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(
            output,
            contains(
                'DeepCollectionEquality().equals(metadata, other.metadata)'));
        expect(output, contains('DeepCollectionEquality().hash(metadata)'));
      });

      test('handles Set fields with DeepCollectionEquality', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'tags',
                  type: 'Set<String>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  isRequired: true,
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output,
            contains('DeepCollectionEquality().equals(tags, other.tags)'));
        expect(output, contains('DeepCollectionEquality().hash(tags)'));
      });

      test('serializes and deserializes Set fields through JSON-safe lists',
          () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'tags',
                  type: 'Set<String>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  isRequired: true,
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains("'tags': tags.toList(),"));
        expect(
            output,
            contains(
                "SafeCasteUtil.readRequiredValue<List<dynamic>>(json, 'tags')"));
        expect(output, contains('.toSet()'));
      });

      test('uses enum converters for enum collections instead of firstWhere',
          () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'statuses',
                  type: 'List<Status>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  isInnerEnum: true,
                ),
                FieldInfo(
                  name: 'statusSet',
                  type: 'Set<Status>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  isInnerEnum: true,
                  isRequired: true,
                ),
                FieldInfo(
                  name: 'statusMap',
                  type: 'Map<String, Status>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  isInnerEnum: true,
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, isNot(contains('firstWhere((ev) => ev.name ==')));
        expect(
          output,
          contains(
            'e is Status ? e : (const DefaultEnumConverter<Status>(Status.values).fromJson(SafeCasteUtil.safeCast<String>(e)) ?? Status.values.first)',
          ),
        );
        expect(
          output,
          contains(
            'v is Status ? v : (const DefaultEnumConverter<Status>(Status.values).fromJson(SafeCasteUtil.safeCast<String>(v)) ?? Status.values.first)',
          ),
        );
      });

      test('accepts enum instances returned by readValue for enum fields', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'status',
                  type: 'Status?',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  isEnum: true,
                  jsonKey: JsonKeyInfo(
                    name: '',
                    alternateNames: [],
                    readValue: 'readStatus',
                    ignore: false,
                  ),
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(
          output,
          contains(
            "status: ((dynamic v) => (v is Status ? v : const DefaultEnumConverter<Status>(Status.values).fromJson(SafeCasteUtil.safeCast<String>(v))))(readStatus(json, 'status'))",
          ),
        );
      });

      test('uses JsonKey name for JSON keys', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'userName',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  jsonKey: JsonKeyInfo(
                    name: 'user_name',
                    alternateNames: [],
                    readValue: '',
                    ignore: false,
                  ),
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains("'user_name': userName,"));
        // Uses SafeCasteUtil.readValue with the json key name
        expect(output, contains("'user_name'"));
      });

      test('skips ignored fields in JSON serialization', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'name',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
                FieldInfo(
                  name: 'password',
                  type: 'String',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                  jsonKey: JsonKeyInfo(
                    name: '',
                    alternateNames: [],
                    readValue: '',
                    ignore: true,
                  ),
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);
        final output = writer.generate();

        expect(output, contains("'name': name,"));
        expect(output, isNot(contains("'password': password,")));
      });
    });

    group('UnsupportedTypeException', () {
      test('throws for unsupported List inner type', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'items',
                  type: 'List<CustomUnsupportedType>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);

        expect(
          () => writer.generate(),
          throwsA(isA<UnsupportedTypeException>()),
        );
      });

      test('throws for unsupported Map key type', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'items',
                  type: 'Map<int, String>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);

        expect(
          () => writer.generate(),
          throwsA(isA<UnsupportedTypeException>()),
        );
      });

      test('throws for unsupported Map value type', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'items',
                  type: 'Map<String, CustomUnsupportedType>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);

        expect(
          () => writer.generate(),
          throwsA(isA<UnsupportedTypeException>()),
        );
      });

      test('preserves nested generic Map value type in error details', () {
        final result = ParseResult(
          '',
          'test',
          [
            const ClassInfo(
              name: 'User',
              mixinName: '_\$User',
              fields: [
                FieldInfo(
                  name: 'items',
                  type: 'Map<String, Map<String, int>>',
                  isFinal: true,
                  isFunction: false,
                  isRecord: false,
                  defaultValue: '',
                ),
              ],
              deepCopyWith: false,
            ),
          ],
          [],
        );

        final writer = GeneratorWriter(result);

        expect(
          () => writer.generate(),
          throwsA(
            isA<UnsupportedTypeException>().having(
              (e) => e.unsupportedType,
              'unsupportedType',
              'Map<String, int>',
            ),
          ),
        );
      });
    });
  });
}
