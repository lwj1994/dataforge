// @author luwenjie on 2026/01/23 15:30:00
// Circular dependency detection for Dataforge classes

import 'model.dart';

/// Detects circular dependencies between Dataforge classes
class CircularDependencyDetector {
  final Map<String, Set<String>> _dependencies = {};
  final Map<String, ClassInfo> _classInfoMap = {};

  /// Adds a class and its dependencies to the detector
  void addClass(ClassInfo classInfo) {
    _classInfoMap[classInfo.name] = classInfo;

    final dependencies = <String>{};
    for (final field in classInfo.fields) {
      // Skip ignored fields
      if (field.jsonKey?.ignore == true) continue;

      // Check if this is a collection type with inner Dataforge types
      if (field.isInnerDataforge) {
        final innerType = _extractGenericType(field.type);
        if (innerType != null) {
          dependencies.add(innerType);
        }
      }
      // Check if this is a direct Dataforge type
      else if (field.isDataforge) {
        final typeName = _extractBaseTypeName(field.type);
        dependencies.add(typeName);
      }
    }

    _dependencies[classInfo.name] = dependencies;
  }

  /// Detects all circular dependencies in the registered classes
  /// Returns a list of dependency cycles, where each cycle is a list of class names
  List<List<String>> detectCycles() {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>[];

    void dfs(String className) {
      // If we've already fully explored this node, skip it
      if (visited.contains(className)) return;

      // If we find this node in our current path, we have a cycle
      if (recursionStack.contains(className)) {
        final cycleStart = recursionStack.indexOf(className);
        final cycle = [
          ...recursionStack.sublist(cycleStart),
          className,
        ];

        // Only add if we haven't seen this cycle before (in any rotation)
        if (!_containsCycle(cycles, cycle)) {
          cycles.add(cycle);
        }
        return;
      }

      // Add to recursion stack
      recursionStack.add(className);

      // Explore dependencies
      for (final dependency in _dependencies[className] ?? <String>{}) {
        // Only follow dependencies that are registered Dataforge classes
        if (_dependencies.containsKey(dependency)) {
          dfs(dependency);
        }
      }

      // Remove from recursion stack and mark as visited
      recursionStack.removeLast();
      visited.add(className);
    }

    // Start DFS from each class
    for (final className in _dependencies.keys) {
      if (!visited.contains(className)) {
        dfs(className);
      }
    }

    return cycles;
  }

  /// Checks if a cycle already exists in the list (accounting for rotations)
  bool _containsCycle(List<List<String>> cycles, List<String> newCycle) {
    // Remove duplicate at end for comparison
    final cleanCycle = newCycle.sublist(0, newCycle.length - 1);

    for (final existingCycle in cycles) {
      if (_areCyclesEqual(existingCycle, cleanCycle)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if two cycles are equal (accounting for rotations)
  bool _areCyclesEqual(List<String> cycle1, List<String> cycle2) {
    if (cycle1.length != cycle2.length) return false;

    // Check all rotations
    for (var i = 0; i < cycle1.length; i++) {
      var match = true;
      for (var j = 0; j < cycle1.length; j++) {
        if (cycle1[j] != cycle2[(i + j) % cycle2.length]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }

    return false;
  }

  /// Extracts the base type name from a type string
  /// Examples:
  ///   "User?" -> "User"
  ///   "List<Post>" -> "List"
  ///   "Map<String, User>" -> "Map"
  String _extractBaseTypeName(String type) {
    var cleanType = type.replaceAll('?', '').trim();
    final genericStart = cleanType.indexOf('<');
    if (genericStart != -1) {
      cleanType = cleanType.substring(0, genericStart);
    }
    return cleanType;
  }

  /// Extracts the inner generic type
  /// Examples:
  ///   "List<User>" -> "User"
  ///   "Map<String, Post>" -> "Post" (returns last type)
  ///   "List<User>?" -> "User"
  String? _extractGenericType(String type) {
    final cleanType = type.replaceAll('?', '').trim();
    final match = RegExp(r'<([^>]+)>').firstMatch(cleanType);
    if (match != null) {
      final inner = match.group(1)!;
      // For Map<K, V>, return V (the value type)
      if (inner.contains(',')) {
        return inner.split(',').last.trim();
      }
      return inner.trim();
    }
    return null;
  }

  /// Generates a user-friendly warning message for detected cycles
  static String formatCycleWarning(List<List<String>> cycles) {
    if (cycles.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('⚠️  Circular dependency detected!');
    buffer.writeln();

    for (var i = 0; i < cycles.length; i++) {
      final cycle = cycles[i];
      buffer.writeln('  Cycle ${i + 1}: ${cycle.join(' → ')}');
    }

    buffer.writeln();
    buffer.writeln(
        'This may cause issues if your JSON data contains circular references.');
    buffer.writeln('Consider one of the following solutions:');
    buffer.writeln(
        '  1. Use @JsonKey(ignore: true) on one side of the relationship');
    buffer
        .writeln('  2. Use ID references instead of direct object references');
    buffer.writeln(
        '  3. Ensure your JSON data does not contain circular references');

    return buffer.toString();
  }

  /// Clears all registered classes and dependencies
  void clear() {
    _dependencies.clear();
    _classInfoMap.clear();
  }
}
