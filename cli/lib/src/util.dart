// @author luwenjie on 20/04/2025 12:34:21

// Extension for type detection
extension StringExtension on String {
  bool isDateTime() => this == 'DateTime' || startsWith('DateTime');
  bool isUri() => this == 'Uri';
  bool isDuration() => this == 'Duration';
  bool isBigInt() => this == 'BigInt';

  bool isPrimitiveType() {
    const primitives = {'String', 'int', 'double', 'bool', 'num'};
    return primitives.contains(replaceAll('?', ''));
  }

  bool isMap() {
    final index = indexOf("<");
    if (index == -1) return false;
    final p = substring(0, index);
    return p.endsWith("Map");
  }

  bool isSet() {
    final index = indexOf("<");
    if (index == -1) return false;
    final p = substring(0, index);
    return p.endsWith("Set");
  }

  bool isList() {
    final index = indexOf("<");
    if (index == -1) return false;
    final p = substring(0, index);
    return p.endsWith("List");
  }

  bool isQueue() {
    final index = indexOf("<");
    if (index == -1) return false;
    final p = substring(0, index);
    return p.endsWith("Queue");
  }

  bool isIterable() {
    final index = indexOf("<");
    if (index == -1) return false;
    final p = substring(0, index);
    return p.endsWith("Iterable");
  }

  bool isCollection() {
    return isList() || isSet() || isMap() || isQueue() || isIterable();
  }
}
