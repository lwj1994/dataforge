# Cross-File Dependency Issue

## Problem Description

Dataforge generator cannot generate flattened field methods (e.g., `$token_type`) when the nested class is defined in a different file, even if the nested class has proper `@Dataforge` annotation.

## Issue Details

### Scenario
- **Main file**: `/path/to/model.dart` contains `TokenCreateSinglePageState` with a `token` field of type `TokenBean`
- **Dependency file**: `/path/to/bean_base.dart` contains `TokenBean` class with `@dataforge_annotation.Dataforge()` annotation
- **Expected**: Generate `$token_type` method for flattened field access
- **Actual**: No flattened field methods are generated for `token` field

### Root Cause

1. **Limited Class Discovery**: The `_findClassInfoByType` method in `writer.dart` only searches within `result.classes`, which contains classes defined in the current file being processed.

2. **Cross-File Limitation**: When processing `model.dart`, the generator cannot access `TokenBean`'s class information from `bean_base.dart`, even though it's properly annotated.

3. **Flattened Field Generation Failure**: The `_collectFlattenedFields` method fails to find `TokenBean`'s ClassInfo, causing it to skip flattened field generation for the `token` field.

### Technical Flow

```dart
// In _collectFlattenedFields method
final nestedClassInfo = _findClassInfoByType(field.type, result.classes);
if (nestedClassInfo == null) {
  // TokenBean not found in current file's classes
  // Skip flattened field generation
  continue;
}
```

## Impact

- Users cannot use convenient flattened field update methods like `$token_type` for cross-file dependencies
- Inconsistent behavior between same-file and cross-file nested objects
- Reduced developer experience when working with modular code structures

## Potential Solutions

### Option 1: Import-Based Class Discovery (Recommended)
- Parse import statements in the current file being processed
- Traverse imported files to find classes with `@Dataforge` annotation
- Build class registry from imported dependencies
- If class not found in imports, skip flattened field generation
- **Advantages**: Follows natural dependency flow, minimal performance impact
- **Implementation**: Extend `_findClassInfoByType` to search imported files

### Option 2: Enhanced Class Discovery
- Implement cross-file class information resolution
- Parse imported files to build a comprehensive class registry
- Maintain dependency graph for proper processing order

### Option 3: Multi-File Processing
- Allow processing multiple related files simultaneously
- Build unified class information across all processed files
- Generate consistent flattened fields for all dependencies

### Option 4: External Class Registry
- Create a separate registry/cache for annotated classes
- Allow generators to query class information across project boundaries
- Implement incremental updates for better performance

## Workarounds

1. **Same-File Definition**: Move nested class definitions to the same file (not always practical)
2. **Manual Methods**: Implement custom update methods manually
3. **Traditional copyWith**: Use nested copyWith chains instead of flattened fields

## Test Cases

- ✅ Same-file nested objects generate flattened fields correctly
- ❌ Cross-file nested objects with @Dataforge annotation fail to generate flattened fields
- ✅ Cross-file nested objects work with traditional copyWith methods

## Priority

**Medium-High**: This affects code organization flexibility and developer experience, especially in larger projects with modular structures.

## Related Files

- `lib/src/writer.dart`: Contains `_findClassInfoByType` and `_collectFlattenedFields` methods
- `lib/src/parser.dart`: Handles file parsing and class discovery
- `test/models/token_create_single_page_state_test.model.dart`: Contains working same-file example

---

*Issue identified on: 2024*
*Status: Open*
*Assignee: TBD*