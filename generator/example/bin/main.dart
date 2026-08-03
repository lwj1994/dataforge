import 'package:dataforge_generator_example/example.dart';

void main() {
  final externalTags = <String>['immutable'];
  final user = User(name: 'milu', tags: externalTags, role: Role.admin);
  externalTags.add('mutated');

  final team = Team(
    id: 'core',
    members: <User>[user],
    scores: <String, Set<int?>>{
      'quality': <int?>{1, null},
    },
  );
  final restored = Team.fromJson(team.toJson());

  if (user.tags.length != 1 || team != restored) {
    throw StateError('Dataforge v1 example failed.');
  }
  print('Dataforge v1 example passed.');
}
