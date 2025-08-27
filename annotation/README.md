# dataclass_annotation

Annotations for the `dataforge` package to forge data classes with JSON serialization support.

## Features

- `@DataClass` annotation to mark classes for code generation
- `@JsonKey` annotation to customize JSON serialization behavior
- Configuration options for code generation

## Usage

```dart
import 'package:dataforge_annotation/dataforge_annotation.dart';

@DataClass()
class User {
  final String name;
  @JsonKey(name: 'user_id')
  final int id;
  
  User({required this.name, required this.id});
}
```

This package provides the annotations used by `dataforge` to forge data classes with JSON serialization methods.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dataclass_annotation: ^0.1.0
```

## License

MIT License - see the [LICENSE](LICENSE) file for details.