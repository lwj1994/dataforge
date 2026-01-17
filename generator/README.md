# dataforge_generator

Code generator for `dataforge` package using `build_runner`.

## Features

- Generates data class code with `build_runner`
- Supports all `@Dataforge` annotation features
- Compatible with `dataforge_annotation`
- Generates mixins with:
  - `copyWith` methods (chained or traditional)
  - `toJson`/`fromJson` methods  
  - `==` operator, `hashCode`, `toString`

## Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dataforge_annotation: ^0.3.0

dev_dependencies:
  build_runner: ^2.4.0
  dataforge_generator: ^0.3.0
```

Annotate your classes:

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'user.g.dart';

@Dataforge()
class User with _$User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) => _$User.fromJson(json);
}
```

Run code generation:

```bash
dart run build_runner build
```

Or for continuous generation:

```bash
dart run build_runner watch
```

## Documentation

See the main [dataforge](https://github.com/your_username/dataforge) package for full documentation.
