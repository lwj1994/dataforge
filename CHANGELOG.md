## 0.1.0-dev.0

- Added automatic toString() method generation for all data classes
- Added automatic fromJson() factory method injection into original data class files
- Enhanced default values support for constructor parameters in fromJson() methods
- Improved type handling for complex nested objects and collections
- Fixed various edge cases in JSON serialization and deserialization

## 0.1.0

- Initial release of data_class_gen
- Support for generating data classes from annotated Dart classes
- JSON serialization support with @JsonKey annotations
- Command-line interface for code generation
- Configurable output directory for generated files
