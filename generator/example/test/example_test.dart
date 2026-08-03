import 'package:dataforge_generator_example/example.dart';
import 'package:test/test.dart';

void main() {
  test('v1 models detach nested collections and preserve value semantics', () {
    final externalScores = <String, Set<int?>>{
      'quality': <int?>{1, null},
    };
    final team = Team(
      id: 'core',
      members: <User>[
        User(name: 'milu', tags: <String>['owner'], role: Role.admin),
      ],
      scores: externalScores,
    );

    externalScores['quality']!.add(2);
    externalScores['other'] = <int?>{3};

    expect(team.scores, hasLength(1));
    expect(team.scores['quality'], <int?>{1, null});
    expect(() => team.scores['quality']!.add(4), throwsUnsupportedError);

    final restored = Team.fromJson(team.toJson());
    expect(restored, team);
    expect(restored.hashCode, team.hashCode);
    expect(identical(team.copyWith(), team), isTrue);
  });
}
