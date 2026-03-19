# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dataforge is a Dart code generation tool for creating immutable data classes with JSON serialization. It provides `copyWith`, `fromJson`, `toJson`, `==`, `hashCode`, and `toString` methods via generated mixins.

## Monorepo Structure

Four packages with shared versioning (currently 0.7.0-dev.0):

- **annotation/** — `dataforge_annotation` on pub.dev. Defines `@Dataforge()` and `@JsonKey()` annotations, type converters (`JsonTypeConverter`, `DefaultDateTimeConverter`, `DefaultEnumConverter`), and `SafeCasteUtil`.
- **dataforge_base/** — `dataforge_base` on pub.dev. Core models (`ClassInfo`, `FieldInfo`, `ParseResult`), `BaseParser`, code `Writer`, `CircularDependencyDetector`, and logger. No build_runner dependency.
- **generator/** — `dataforge` on pub.dev. build_runner-based generator. `DataforgeGenerator extends GeneratorForAnnotation<Dataforge>`, with `GeneratorParser` and `GeneratorWriter`.
- **cli/** — `dataforge_cli` on pub.dev. Standalone CLI alternative to build_runner with parallel file processing. Faster for large projects.

**Dependency graph:** `generator` and `cli` both depend on `annotation` and `dataforge_base`. Local development uses `dependency_overrides` for path references.

## Common Commands

Each package is independent — run commands from within the package directory:

```bash
# Install dependencies (per package)
cd <package> && dart pub get

# Run tests (per package)
cd <package> && dart test

# Run a single test file
cd <package> && dart test test/parser_test.dart

# Static analysis (CI uses --fatal-infos)
cd <package> && dart analyze --fatal-infos

# Format check
cd <package> && dart format --set-exit-if-changed .

# Code generation via build_runner (in generator/example or consumer projects)
dart run build_runner build

# Code generation via CLI
dataforge .
dataforge lib/models --debug
```

## Generated Code Conventions

- Generated files use the `.data.dart` extension (not `.g.dart`)
- Generation produces a mixin named `_ClassName` that the source class applies
- Classes annotated with `@Dataforge()` trigger generation
- Field-level customization via `@JsonKey()`

## Code Style

- Dart SDK >=3.0.0
- Linter rules enforced: `always_declare_return_types`, `prefer_single_quotes`, `prefer_const_constructors`
- `*.g.dart` files excluded from analysis

## Architecture Notes

- **Two code generation paths**: build_runner (generator package, uses `source_gen`) and standalone CLI (cli package, uses `analyzer` directly). Both share `BaseParser` and `Writer` from `dataforge_base`.
- **CLI parallel processing**: Uses `Isolate`-based concurrency with `Platform.numberOfProcessors` workers. Pre-filters files for `@Dataforge` annotations before parsing.
- **Type converters**: `SafeCasteUtil` handles lenient type coercion (String↔int, String↔bool with "yes"/"no"/"1"/"0" support). `DefaultDateTimeConverter` auto-detects 10-digit (seconds) vs 13-digit (milliseconds) timestamps vs ISO-8601 strings.

## Publishing

Packages must be published in dependency order with delays: `annotation` → `dataforge_base` → `generator` → `cli`. See `.claude/skills/release.md` for the full release workflow.
