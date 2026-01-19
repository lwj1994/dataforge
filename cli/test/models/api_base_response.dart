import 'package:dataforge_annotation/dataforge_annotation.dart';

import 'utils.dart';

part 'api_base_response.data.dart';

@Dataforge()
class EchoApiResponse<T>
    with _EchoApiResponse<T>, _EchoApiResponse<T>, _EchoApiResponse<T> {
  // int or string ??
  @override
  @JsonKey(name: 'code')
  final String code;

  @override
  @JsonKey(
    name: 'message',
  )
  final String message;

  @override
  @JsonKey(name: "data", readValue: readValue)
  final T? data;

  const EchoApiResponse({
    this.code = "",
    this.message = "",
    this.data,
  });

  factory EchoApiResponse.fromJson(Map<String, dynamic> json) {
    return _EchoApiResponse.fromJson(json);
  }
}

class EchoApiResponseConverter<T> extends JsonTypeConverter<T, dynamic> {
  const EchoApiResponseConverter();

  @override
  T? fromJson(dynamic json) {
    if (json is String) {
      return json as T;
    }
    return null;
  }

  @override
  dynamic toJson(T? object) {
    return null;
  }
}
