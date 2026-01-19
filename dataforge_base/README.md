# Dataforge Base

Base package for the [Dataforge](https://pub.dev/packages/dataforge_generator) ecosystem.

This package provides the core shared logic used by the Dataforge CLI and Generator, including:
- Data Class Models (`FieldInfo`, `ClassInfo`, etc.)
- Parsing Logic (Parsing ASTs using `analyzer`)
- Writing Logic (Generating code strings)

## Installation

This package is typically used as a dependency for `dataforge_generator` or `dataforge_cli`.

```yaml
dependencies:
  dataforge_base: ^0.1.0
```

## Features

- **Models**: Defines structure of data classes.
- **Parser**: Extracts models from Analyzer `Element`s.
- **Writer**: Generates Dart code for `copyWith`, `toJson`, `fromJson`, etc.

**Internal Use Only**: This package is primarily intended for internal use by `dataforge_cli` and `dataforge_generator`.
