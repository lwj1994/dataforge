import 'package:dataforge_annotation/dataforge_annotation.dart';

part 'api_base_response.data.dart';

@Dataforge()
class EchoApiResponse<T>
    with _EchoApiResponse<T>, _EchoApiResponse<T>, _EchoApiResponse<T> {
  // int or string ??
  @JsonKey(name: 'code', readValue: _readApiResponseValue)
  final String code;

  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: "data", fromJson: jsonToObject)
  final T? data;

  const EchoApiResponse({
    this.code = "22",
    this.message = "",
    this.data,
  });

  @override
  String toString() {
    return 'EchoApiResponse{code: $code, message: $message, data: $data}';
  }

  factory EchoApiResponse.fromJson(Map<String, dynamic> json) =>
      _EchoApiResponse.fromJson(json);
}

T? jsonToObject<T>(Object? json, {String? typeName}) {
  return null;
}

Object? _readApiResponseValue(Map<dynamic, dynamic> map, String key) {
  return null;
}
