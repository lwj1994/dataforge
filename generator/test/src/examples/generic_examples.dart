import 'package:dataforge_annotation/dataforge_annotation.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(r'''
mixin _GenericResult<T> {
  abstract final T? data;
  @pragma('vm:prefer-inline')
  _GenericResultCopyWith<T, GenericResult<T>> get copyWith =>
      _GenericResultCopyWith<T, GenericResult<T>>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GenericResult) return false;

    return other.data == data;
  }

  @override
  int get hashCode => Object.hashAll([data]);

  @override
  String toString() => 'GenericResult(data: $data)';

  Map<String, dynamic> toJson() {
    return {'data': data};
  }

  static GenericResult<T> fromJson<T>(Map<String, dynamic> json) {
    return GenericResult(data: json['data']);
  }
}

class _GenericResultCopyWith<T, R> {
  final _GenericResult<T> _instance;
  final R Function(GenericResult<T>)? _then;
  _GenericResultCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({Object? data = dataforgeUndefined}) {
    final res = GenericResult<T>(
      data: SafeCasteUtil.copyWithCastNullable<T>(data, 'data', _instance.data),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R data(T? value) {
    final res = call(data: value);
    return res;
  }
}
''')
@Dataforge()
class GenericResult<T> {
  final T? data;
  GenericResult({this.data});
}

@ShouldGenerate(r'''
mixin _MultiGenericExample<T, U> {
  abstract final T first;
  abstract final U second;
  @pragma('vm:prefer-inline')
  _MultiGenericExampleCopyWith<T, U, MultiGenericExample<T, U>> get copyWith =>
      _MultiGenericExampleCopyWith<T, U, MultiGenericExample<T, U>>._(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MultiGenericExample) return false;

    return other.first == first && other.second == second;
  }

  @override
  int get hashCode => Object.hashAll([first, second]);

  @override
  String toString() => 'MultiGenericExample(first: $first, second: $second)';

  Map<String, dynamic> toJson() {
    return {'first': first, 'second': second};
  }

  static MultiGenericExample<T, U> fromJson<T, U>(Map<String, dynamic> json) {
    return MultiGenericExample(first: json['first'], second: json['second']);
  }
}

class _MultiGenericExampleCopyWith<T, U, R> {
  final _MultiGenericExample<T, U> _instance;
  final R Function(MultiGenericExample<T, U>)? _then;
  _MultiGenericExampleCopyWith._(this._instance, [this._then]);

  @pragma('vm:prefer-inline')
  R call({
    Object? first = dataforgeUndefined,
    Object? second = dataforgeUndefined,
  }) {
    final res = MultiGenericExample<T, U>(
      first: SafeCasteUtil.copyWithCast<T>(first, 'first', _instance.first),
      second: SafeCasteUtil.copyWithCast<U>(second, 'second', _instance.second),
    );
    return (_then != null ? _then!(res) : res as R);
  }

  @pragma('vm:prefer-inline')
  R first(T value) {
    final res = call(first: value);
    return res;
  }

  @pragma('vm:prefer-inline')
  R second(U value) {
    final res = call(second: value);
    return res;
  }
}
''')
@Dataforge()
class MultiGenericExample<T, U> {
  final T first;
  final U second;

  MultiGenericExample({required this.first, required this.second});
}

// Note: BoundedGenericExample<T extends num> is supported by the generator,
// but source_gen_test's formatter has issues parsing type bounds like "T extends num".
// The generated code is correct but cannot be tested with @ShouldGenerate.
// Uncomment below to verify manually that it compiles:
// @Dataforge()
// class BoundedGenericExample<T extends num> {
//   final T value;
//   final T? optionalValue;
//   BoundedGenericExample({required this.value, this.optionalValue});
// }

// Note: GenericListExample<T> with List<T> is NOT supported by the generator.
// The generator throws: "Unsupported nested type in List: T for field items.
// Only primitives, enums, dataforge objects, and Map<String, dynamic> are supported."
// This is a known limitation - List<T> with generic type parameter cannot be processed
// because the generator doesn't know what T is at generation time.
//
// If you need a list of generic type, consider using:
// - List<dynamic> and casting at runtime
// - A specific type instead of generic T
